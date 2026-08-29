local addonName, BossW = ...

-- ============================================================
-- AURA ENGINE (WoW 12.1+ — AuraContainer intrinsic path)
-- ------------------------------------------------------------
-- 12.1 sealed Lua aura READS in combat: index/slot/instanceID reads
-- hard-error while auras are secret, and the UNIT_AURA payload is fully
-- secret. On hostile boss units it's even stricter. The v0.8.8 pcall
-- hardening stopped the error spam but left the legacy scan path BLIND
-- in combat — empty aura row exactly when it matters.
--
-- The fix is declarative display: the addon CREATES + STYLES the
-- buttons, Blizzard's secure code FILLS + DRIVES them (secrets
-- included). We declare the query — filter string + candidateFilters
-- evaluated C-side against the real data — and never observe contents.
-- Bonus: the source filter (Only mine / Boss-cast only) becomes exact
-- on Retail again, because the secure matcher reads the real
-- isFromPlayerOrPlayerPet / isBossAura flags we lost to secrets.
--
-- Reference implementation: TankWatch Frames/AuraEngine.lua (v1.5.1,
-- live-combat validated). Pattern sources: DandersFrames
-- Frames/AuraContainer.lua, BigWigs_Plugins/Auras.lua.
--
-- Build order (do not reorder):
--   CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
--   -> geometry -> SetUnit -> AddAuraGroup -> SetEnabled(true) LAST.
--   Build/mutate OUT OF COMBAT only.
--
-- ☠ Hard rules (each cost a field bug somewhere in the family):
--   * NEVER pass a formatter to SetApplicationCount — Blizzard's
--     formatter path runs in Lua with the SECRET count and bricks the
--     container for the session. Bare FontString only.
--   * NOTHING may anchor TO the container or its buttons (forbidden
--     aspects) — geometry lives on a plain invisible shadow box.
--   * Cell size comes from the GROUP layout table, not button SetSize.
--   * Only touch existing buttons behind CanBeAccessedInContext(),
--     pcall everything — buttons can turn forbidden mid-pass.
--   * NEVER SwitchAuraDataProvider for test mode (global, breaks every
--     container in the client). Test mode stays on legacy painted
--     buttons.
-- ============================================================

local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown

BossW.AuraEngine = {}
local AE = BossW.AuraEngine

-- nil = not probed yet (or probe deferred by combat), true/false = final
local supported = nil

local function probeSupported()
    if InCombatLockdown and InCombatLockdown() then return nil end
    local toc = select(4, GetBuildInfo())
    if type(toc) ~= "number" or toc < 120100 then return false end
    if not (AuraUtil and AuraUtil.IsValidFilterString) then return false end
    local ok, c = pcall(CreateFrame, "AuraContainer", nil, UIParent,
                        "CustomAuraContainerTemplate")
    if not ok or not c then return false end
    local hasGroups = type(c.AddAuraGroup) == "function"
    pcall(c.Hide, c)
    return hasGroups
end

function AE.IsSupported()
    if supported == nil then supported = probeSupported() end
    return supported == true
end

function AE.IsActive(f)
    return f and f._acActive or false
end

-- ============================================================
-- CANDIDATE FILTERS — BossWatch's aurasSource dropdown maps 1:1 onto
-- boolean candidate filters evaluated by the secure matcher:
--   ALL       -> {}
--   MINE      -> isFromPlayerOrPlayerPet = true
--   NOT_MINE  -> isFromPlayerOrPlayerPet = false
--   BOSS_ONLY -> isBossAura = true
-- ============================================================
local function buildCandidateFilters(db)
    local source = db.aurasSource or "ALL"
    if source == "MINE" then return { isFromPlayerOrPlayerPet = true } end
    if source == "NOT_MINE" then return { isFromPlayerOrPlayerPet = false } end
    if source == "BOSS_ONLY" then return { isBossAura = true } end
    return {}
end

local function buildSig(db, unit)
    return table.concat({
        tostring(unit),
        tostring(db.showAuras), tostring(db.aurasFilter), tostring(db.aurasSource),
        tostring(db.aurasMaxCount), tostring(db.aurasSize), tostring(db.aurasSpacing),
        tostring(db.aurasAnchor), tostring(db.aurasGrowX),
        tostring(db.aurasX), tostring(db.aurasY),
        tostring(db.aurasShowStacks), tostring(db.aurasStackAnchor),
        tostring(db.aurasStackX), tostring(db.aurasStackY),
        tostring(db.aurasShowTimer), tostring(db.aurasTimerPlacement),
        tostring(db.aurasTimerX), tostring(db.aurasTimerY),
        tostring(db.aurasTooltip),
    }, "|")
end

-- ============================================================
-- DURATION TEXT FORMAT — compact "45" -> "2m" -> "1h" (matches the
-- legacy formatTime look), C-evaluated so combat-safe. Recipe and
-- build-68914 binding dance copied from the TankWatch engine.
-- ============================================================
local PROMOTE_MIN  = 1 + 1.5 * 60
local PROMOTE_HOUR = 1 + 1.5 * 3600

local durFormatter
local function getDurationFormatter()
    if durFormatter ~= nil then return durFormatter or nil end
    if not (C_StringUtil and C_StringUtil.CreateNumericRuleFormatter
            and Enum and Enum.NumericRuleFormatRounding) then
        durFormatter = false
        return nil
    end
    local ok, f = pcall(function()
        local down = Enum.NumericRuleFormatRounding.Down
        local up   = Enum.NumericRuleFormatRounding.Up
        local fmt = C_StringUtil.CreateNumericRuleFormatter()
        fmt:AddBreakpoint({ threshold = 0, step = 1, rounding = up, min = 1,
                            format = "%d" })
        fmt:AddBreakpoint({ threshold = PROMOTE_MIN, step = 1, rounding = down, min = 1,
                            format = "%dm", components = { { div = 60, rounding = up } } })
        fmt:AddBreakpoint({ threshold = PROMOTE_HOUR, step = 1, rounding = down, min = 1,
                            format = "%dh", components = { { div = 3600, rounding = up } } })
        return fmt
    end)
    durFormatter = ok and f or false
    return durFormatter or nil
end

local durBinding
local function getDurationTextOpts()
    local fmt = getDurationFormatter()
    if not fmt then return nil end
    if C_AuraContainerUtil
       and type(C_AuraContainerUtil.ProcessCustomAuraButtonDurationTextOptions) == "function" then
        if durBinding == nil then
            if C_DurationUtil and C_DurationUtil.CreateDurationTextBinding then
                local ok, b = pcall(function()
                    local bind = C_DurationUtil.CreateDurationTextBinding()
                    bind:SetFormatter(fmt)
                    bind:SetEnabled(true)
                    return bind
                end)
                durBinding = (ok and b) or false
            else
                durBinding = false
            end
        end
        if durBinding then return { binding = durBinding } end
        return nil
    end
    return { formatter = fmt }
end

local function buildGroupLayout(db)
    local size    = db.aurasSize or 22
    local spacing = db.aurasSpacing or 2
    return {
        elementWidth    = size,
        elementHeight   = size,
        elementSpacing  = spacing, -- 68914+
        lineSpacing     = spacing, -- 68914+
        groupSpacing    = 0,       -- 68914+
        elementSpacingX = spacing, -- pre-68914 twin
        elementSpacingY = spacing, -- pre-68914 twin
        gapX            = 0,       -- pre-68914 twin
    }
end

-- ============================================================
-- BUTTON REGIONS — same visual recipe as the legacy painted buttons:
-- zoomed icon, 1px black border, cooldown swipe without numbers,
-- stacks + timer per the user's anchor/placement settings.
-- ============================================================
local function styleButton(f, btn, db)
    local size = db.aurasSize or 22
    pcall(btn.SetSize, btn, size, size)

    if btn.stacks then
        pcall(function()
            btn.stacks:ClearAllPoints()
            local sa = db.aurasStackAnchor or "BOTTOMRIGHT"
            btn.stacks:SetPoint(sa, btn, sa, db.aurasStackX or 0, db.aurasStackY or 0)
            btn.stacks:SetShown(db.aurasShowStacks ~= false)
        end)
    end
    if btn.timer then
        pcall(function()
            btn.timer:ClearAllPoints()
            local place = db.aurasTimerPlacement or "BELOW"
            local tx, ty = db.aurasTimerX or 0, db.aurasTimerY or 0
            if place == "BELOW" then btn.timer:SetPoint("TOP", btn, "BOTTOM", tx, ty - 1)
            elseif place == "ABOVE" then btn.timer:SetPoint("BOTTOM", btn, "TOP", tx, ty + 1)
            else btn.timer:SetPoint("CENTER", btn, "CENTER", tx, ty) end
            btn.timer:SetShown(db.aurasShowTimer ~= false)
        end)
    end
    -- Native tooltip on hover, honoring the user's toggle; clicks always
    -- pass through to the world.
    if btn.SetMouseMotionEnabled then
        pcall(btn.SetMouseMotionEnabled, btn, db.aurasTooltip ~= false)
    end
end

local function initButton(f, btn)
    local db = BossW:GetDB()
    if btn._bwInit then
        styleButton(f, btn, db)
        return
    end
    btn._bwInit = true

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(btn)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon
    pcall(btn.SetIcon, btn, icon)

    local border = btn:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0, 0, 0, 0.9)
    btn.border = border

    local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    cd:SetAllPoints(btn)
    cd:SetHideCountdownNumbers(true)
    cd:SetDrawEdge(false); cd:SetDrawSwipe(true)
    btn.cd = cd
    pcall(btn.SetDurationCooldown, btn, cd)

    -- Timer + stacks on the cooldown frame so they draw above the swipe.
    local timer = cd:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    timer:SetTextColor(1, 0.9, 0.1)
    timer:SetShadowColor(0, 0, 0, 1)
    timer:SetShadowOffset(1, -1)
    timer:SetDrawLayer("OVERLAY", 7)
    btn.timer = timer
    if btn.SetDurationText then
        local opts = getDurationTextOpts()
        if not (opts and pcall(btn.SetDurationText, btn, timer, opts)) then
            if not pcall(btn.SetDurationText, btn, timer) then
                pcall(btn.SetDurationText, btn, timer, {})
            end
        end
    end

    local stacks = cd:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    stacks:SetJustifyH("RIGHT")
    stacks:SetTextColor(1, 1, 1)
    stacks:SetShadowColor(0, 0, 0, 1)
    stacks:SetShadowOffset(1, -1)
    stacks:SetDrawLayer("OVERLAY", 7)
    btn.stacks = stacks
    -- ⚠ bare FontString, NO formatter — see header.
    if btn.SetApplicationCount then
        pcall(btn.SetApplicationCount, btn, stacks)
    end

    -- Register texts so BossW:ApplyFonts reaches them, and apply the
    -- current font right away (buttons can spawn mid-combat).
    f._acTexts = f._acTexts or {}
    f._acTexts[#f._acTexts + 1] = { timer = timer, stacks = stacks }
    local file = BossW:ResolveFont(db.fontFace)
    local sz = db.fontSize or 12
    local outline = db.fontOutline or "NONE"
    if outline == "NONE" or outline == "" then outline = "OUTLINE" end
    pcall(timer.SetFont, timer, file, sz, outline)
    pcall(stacks.SetFont, stacks, file, sz, outline)

    styleButton(f, btn, db)
end

-- ============================================================
-- GEOMETRY — fixed shadow box the size of the full row; the container
-- fills the box (protected-depends-on-unprotected is allowed) and the
-- flow layout grows from the row's origin side. Mirrors LayoutAuras.
-- ============================================================
local function mirrorAnchor(a)
    if a == "CENTER" then return "CENTER" end
    if a == "TOP" then return "BOTTOM" end
    if a == "BOTTOM" then return "TOP" end
    if a:find("LEFT") then return (a:gsub("LEFT", "RIGHT")) end
    if a:find("RIGHT") then return (a:gsub("RIGHT", "LEFT")) end
    return a
end

local function applyGeometry(f, c, db)
    local size     = db.aurasSize or 22
    local spacing  = db.aurasSpacing or 2
    local maxCount = math.min(math.max(db.aurasMaxCount or 3, 1), 8)
    local w = maxCount * size + math.max(0, maxCount - 1) * spacing

    local box = f._acShadow
    if not box then
        box = CreateFrame("Frame", nil, f)
        f._acShadow = box
    end
    box:SetSize(math.max(w, size), size)

    local anchor = db.aurasAnchor or "LEFT"
    local growX  = db.aurasGrowX or "LEFT"

    box:ClearAllPoints()
    -- Legacy places button 1 AT the anchor and grows outward; the shadow
    -- box reserves the full row, so anchor the box's edge that matches
    -- where button 1 sits: for LEFT growth the row extends leftward from
    -- the anchor → the box's RIGHT edge sits at the anchor point.
    local boxPoint = (growX == "LEFT") and "RIGHT" or "LEFT"
    if anchor == "CENTER" then boxPoint = "CENTER" end
    box:SetPoint(boxPoint, f, anchor, db.aurasX or 0, db.aurasY or 0)

    pcall(c.ClearAllPoints, c)
    pcall(c.SetAllPoints, c, box)

    local originLeft = (growX ~= "LEFT")
    if c.SetFlowLayoutAnchorPoint then
        pcall(c.SetFlowLayoutAnchorPoint, c, originLeft and "LEFT" or "RIGHT")
    end
    if c.SetFlowLayoutGrowthDirection and AnchorUtil and AnchorUtil.FlowDirection then
        local FD = AnchorUtil.FlowDirection
        local h = originLeft and (FD.Right or FD.RIGHT) or (FD.Left or FD.LEFT)
        local v = FD.Down or FD.DOWN
        if h ~= nil and v ~= nil then
            pcall(c.SetFlowLayoutGrowthDirection, c, h, v)
        end
    end
    if c.SetFlowLayoutPadding then pcall(c.SetFlowLayoutPadding, c, spacing, spacing) end
    if c.SetFlowLayoutMaximumLineSize then pcall(c.SetFlowLayoutMaximumLineSize, c, w + 1) end
end

-- ============================================================
-- APPLY — called from ApplyLayout per boss frame (OOC-gated by the
-- _pendingLayout machinery). Returns true when the engine owns aura
-- rendering for this frame: caller parks legacy buttons and skips
-- BossW.UpdateAuras / the UNIT_AURA repaint.
-- ============================================================
local function parkContainer(f)
    if f._ac then
        pcall(f._ac.SetEnabled, f._ac, false)
        f._ac:Hide()
    end
    f._acActive = false
    f._acSig = nil
end

function AE.Apply(f, db)
    if not f then return false end
    if supported == nil then supported = probeSupported() end
    if supported ~= true then return false end
    db = db or BossW:GetDB()

    -- Test mode previews through the legacy painted buttons (the
    -- container can't be fed fake auras — and SwitchAuraDataProvider is
    -- global/forbidden). Park and hand back.
    if f._testMode then
        parkContainer(f)
        return false
    end

    -- Nothing to render: engine still owns the surface (returns true) so
    -- stale legacy buttons don't reappear.
    if not db.showAuras or not f.unit then
        parkContainer(f)
        return true
    end

    -- Defensive: a stray in-combat call must not touch the container.
    if InCombatLockdown and InCombatLockdown() then
        return f._ac ~= nil
    end

    local sig = buildSig(db, f.unit)
    if f._ac and f._acActive and f._acSig == sig then
        f._ac:Show()
        return true
    end

    -- The group's base filter string ("HARMFUL"/"HELPFUL") is fixed at
    -- AddAuraGroup time; if the user flipped it, rebuild the container.
    local filter = db.aurasFilter or "HARMFUL"
    if f._ac and f._acFilter and f._acFilter ~= filter then
        parkContainer(f)
        pcall(f._ac.SetParent, f._ac, nil)
        f._ac = nil
        f._acGroupAdded = nil
    end

    local c = f._ac
    if not c then
        local ok
        ok, c = pcall(CreateFrame, "AuraContainer", nil, f,
                      "CustomAuraContainerTemplate")
        if not ok or not c then
            supported = false
            return false
        end
        f._ac = c
    end

    -- Disarm while mutating, re-arm last.
    pcall(c.SetEnabled, c, false)
    applyGeometry(f, c, db)
    pcall(c.SetUnit, c, f.unit)

    local cf = buildCandidateFilters(db)
    local maxCount = math.min(math.max(db.aurasMaxCount or 3, 1), 8)
    if not f._acGroupAdded then
        local okG = pcall(c.AddAuraGroup, c, "main", filter, {
            maxFrameCount    = maxCount,
            initializeFrame  = function(btn) initButton(f, btn) end,
            sortMethod       = 4, -- Enum.UnitAuraSortRule.ExpirationOnly
            sortDirection    = 0,
            candidateFilters = cf,
            layout           = buildGroupLayout(db),
        })
        if not okG then
            pcall(c.Hide, c)
            supported = false
            return false
        end
        f._acGroupAdded = true
        f._acFilter = filter
    end
    -- Push count/filters/layout through the live setters on BOTH paths —
    -- not just updates. Belt-and-braces against opts-key drift between
    -- builds (observed: containers spawning Blizzard's default pool of 10
    -- buttons despite maxFrameCount in the AddAuraGroup opts).
    if c.SetAuraGroupMaxFrameCount then
        pcall(c.SetAuraGroupMaxFrameCount, c, "main", maxCount)
    end
    if c.SetAuraGroupCandidateFilters then
        pcall(c.SetAuraGroupCandidateFilters, c, "main", cf)
    end
    if c.SetAuraGroupLayout then
        pcall(c.SetAuraGroupLayout, c, "main", buildGroupLayout(db))
    end

    -- Re-style buttons the container already spawned. Buttons are
    -- forbidden while auras are secret — only touch accessible ones.
    if c.GetAuraGroupFrameCount and c.GetAuraGroupFrame then
        local okN, n = pcall(c.GetAuraGroupFrameCount, c, "main")
        if okN and type(n) == "number" then
            for i = 1, n do
                local okB, btn = pcall(c.GetAuraGroupFrame, c, "main", i)
                if okB and btn and btn._bwInit and btn.CanBeAccessedInContext then
                    local okA, acc = pcall(btn.CanBeAccessedInContext, btn)
                    if okA and acc == true then styleButton(f, btn, db) end
                end
            end
        end
    end

    c:Show()
    pcall(c.SetEnabled, c, true) -- LAST — arms the parse + event feed
    if c.UpdateAllAuras then pcall(c.UpdateAllAuras, c) end

    f._acSig = sig
    f._acActive = true
    return true
end

-- ============================================================
-- DIAGNOSTIC (/bossw acdebug)
-- ============================================================
function AE.Debug()
    if supported == nil then supported = probeSupported() end
    print(string.format("|cffeda55fBossWatch:|r AuraEngine supported=%s (toc=%s)",
        tostring(supported), tostring(select(4, GetBuildInfo()))))
    if not BossW.BossFrames then return end
    for i = 1, BossW.MAX_BOSS do
        local f = BossW.BossFrames[i]
        if f and (f.unit or f._testMode or f._ac) then
            local n = "?"
            if f._ac and f._ac.GetAuraGroupFrameCount then
                local ok, v = pcall(f._ac.GetAuraGroupFrameCount, f._ac, "main")
                if ok then n = tostring(v) end
            end
            print(string.format(
                "  [%d] unit=%s test=%s container=%s active=%s buttons=%s",
                i, tostring(f.unit), tostring(f._testMode or false),
                tostring(f._ac ~= nil), tostring(f._acActive or false), n))
        end
    end
end

-- Warm the capability probe at login (and leave nil → retried OOC when
-- the user reloaded mid-combat).
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    if supported == nil then supported = probeSupported() end
end)
