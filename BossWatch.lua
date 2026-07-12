local addonName, BossW = ...

-- Expose the addon table globally for /dump and external access.
_G[addonName] = BossW

BossW.MAX_BOSS = 5
BossW.BossFrames = {}
BossW.BossContainer = nil

-- ============================================================
-- DEFAULTS
-- ============================================================
BossW.Defaults = {
    enabled = true,
    hideBlizzard = true,
    -- Only show the boss frames on multi-boss encounters. When true, frame 1
    -- additionally requires @boss2 to exist — so single-boss encounters
    -- (which is 90% of raid fights) rely on Blizzard's native target frame
    -- and BossWatch stays out of the way. Requested by ethereal84 (CF PM).
    hideOnSingleBoss = false,

    -- Container
    anchor = "RIGHT", anchorX = -50, anchorY = 100,
    frameWidth = 220, frameHeight = 50, frameSpacing = 8, frameScale = 1.0,
    growDirection = "DOWN",
    frameStrata = "MEDIUM",

    -- Portrait (2D Blizzard-style)
    portraitPosition = "RIGHT", portraitSize = 44,

    -- Health
    healthTexture = "Blizzard Raid Bar",
    barBackgroundTexture = "Solid", -- LSM texture used behind HP / Power / Cast bars
    frameBackgroundAlpha = 0.6,     -- alpha of the overall frame backdrop
    healthBackgroundAlpha = 0.35,
    healthColorMode = "REACTION", -- REACTION | CLASS_FALLBACK | STATIC
    healthStaticColor = {r = 0.8, g = 0.1, b = 0.1, a = 1},

    -- Power
    showPowerBar = true, powerBarHeight = 6, powerBackgroundAlpha = 0.7,
    powerTexture = "Blizzard Raid Bar",

    -- Absorbs / shields overlay on the health bar
    showAbsorbs = true,
    absorbTexture = "Blizzard Raid Bar",
    -- #FFEB3EFF — opaque yellow
    absorbColor   = { r = 0xFF/0xFF, g = 0xEB/0xFF, b = 0x3E/0xFF, a = 0xFF/0xFF },

    -- Cast
    castTexture = "Blizzard Modern",
    showCastBar = true, castBarHeight = 14, castBarDetached = false,
    -- When false, the frame bg stops above the cast zone — that area is only
    -- visible when an actual cast happens. When true, frame bg wraps everything.
    frameBgWrapsCast = false,
    castBarIconPosition = "LEFT", castBackgroundAlpha = 0.7,
    castBarDetachedAnchor = "BOTTOM", castBarDetachedX = 0, castBarDetachedY = -4,
    castBarDetachedWidth = 0,

    -- Name text
    showName = true, nameAnchor = "RIGHT", nameX = 1, nameY = 0, nameMaxLength = 16,
    layoutBlocks = 3,  -- 3 = name overlaid on HP bar (compact), 4 = name on its own row above HP

    -- Health text
    showHealthText = true, healthTextAnchor = "LEFT", healthTextX = 0, healthTextY = 0,
    healthTextFormat = "CURRENT",

    -- How to format current/max numbers: "RAW" (Blizzard default render),
    -- "K" (force thousands), "M" (force millions), "G" (force billions),
    -- "AUTO" (smart pick via AbbreviateLargeNumbers).
    numberScale = "AUTO",

    -- Font (applies to all text elements)
    fontFace = "Friz Quadrata TT", fontSize = 12, fontOutline = "NONE",

    -- Power text
    showPowerText = true, powerTextAnchor = "RIGHT", powerTextX = -2, powerTextY = 0,
    powerTextFormat = "CURRENT",

    -- Click actions on the boss frame (out-of-combat configurable)
    clickActions = true,

    -- Smooth health bar animation (interpolate between values instead of jumping)
    smoothBars = true,

    -- Target highlight
    targetHighlight = true,
    targetHighlightColorMode = "STATIC", -- STATIC | CLASS | REACTION
    targetHighlightColor = { r = 1, g = 0.82, b = 0, a = 1 }, -- gold (used in STATIC mode)
    targetHighlightAnimate = true,
    targetHighlightThickness = 2,

    -- Raid target icon
    showRaidTargetIcon = true, raidTargetAnchor = "TOP",
    raidTargetX = 0, raidTargetY = 4, raidTargetSize = 18, raidTargetAlpha = 0.9,

    -- Auras
    showAuras = true, aurasFilter = "HARMFUL", aurasSource = "BOSS_ONLY",
    aurasMaxCount = 3, aurasSize = 22, aurasSpacing = 2,
    aurasAnchor = "LEFT", aurasX = -22, aurasY = 0,
    aurasGrowX = "LEFT", aurasGrowY = "DOWN",
    aurasShowStacks = true, aurasStackAnchor = "BOTTOMRIGHT", aurasStackX = 0, aurasStackY = 0,
    aurasShowTimer = true, aurasTimerPlacement = "BELOW", aurasTimerX = 0, aurasTimerY = 0,
    aurasTooltip = true,

    -- SoD / Classic Era detection (only consumed by Frames/SodSlotProvider.lua,
    -- which is loaded ONLY by BossWatch-Vanilla.toc — on Retail/MoP these
    -- keys are seeded into the profile but never read).
    maxBossSoD             = 5,     -- 3, 5 or 8
    sodIncludeWorldBosses  = true,  -- UnitClassification == "worldboss"
    sodIncludeRareElites   = true,  -- UnitClassification == "rareelite"
    sodIncludeElites       = true,  -- UnitClassification == "elite"
    sodIncludeRares        = false, -- UnitClassification == "rare" (silver, non-elite)
    sodReleaseDelay        = 5,     -- seconds out of combat before freeing a slot
                                    -- whose unit token has gone missing
}

-- ============================================================
-- DB ACCESS
-- ============================================================

local function seedDefaults(target)
    for k, v in pairs(BossW.Defaults) do
        if target[k] == nil then
            if type(v) == "table" then
                local c = {}
                for kk, vv in pairs(v) do c[kk] = vv end
                target[k] = c
            else
                target[k] = v
            end
        end
    end
end

-- ============================================================
-- PROFILES
-- ============================================================

function BossW:GetCharKey()
    local name = UnitName("player") or "?"
    local realm = GetRealmName() or "?"
    return name .. " - " .. realm
end

local function migrateLegacyTextures(p)
    if p.healthTexture == "Interface\\AddOns\\BossWatch\\Media\\bar.tga" then
        p.healthTexture = "Blizzard Raid Bar"
    end
    if p.healthTexture == "Blizzard" then p.healthTexture = "Blizzard Raid Bar" end
    if p.powerTexture  == "Blizzard" then p.powerTexture  = "Blizzard Raid Bar" end
    if p.castTexture   == "Blizzard" then p.castTexture   = "Blizzard Modern" end
    if p.castTexture   == "Blizzard Raid Bar" then p.castTexture = "Blizzard Modern" end
end

local function ensureProfilesDB()
    BossWatchDB = BossWatchDB or {}
    -- Migrate flat → profile structure (one-shot)
    if not BossWatchDB.profiles then
        local old = {}
        for k, v in pairs(BossWatchDB) do
            if k ~= "profiles" and k ~= "charBindings" and k ~= "version" and k ~= "minimap" then
                old[k] = v
                BossWatchDB[k] = nil
            end
        end
        BossWatchDB.profiles = { Default = old }
        BossWatchDB.charBindings = {}
        BossWatchDB.version = 1
    end
    BossWatchDB.profiles = BossWatchDB.profiles or {}
    if not BossWatchDB.profiles.Default then BossWatchDB.profiles.Default = {} end
    BossWatchDB.charBindings = BossWatchDB.charBindings or {}
    -- Account-wide minimap state (NOT per-profile). Default = visible so new
    -- users discover the addon entry point without needing to read the README.
    BossWatchDB.minimap = BossWatchDB.minimap or { hide = false }
    -- Account-wide tracker for "NEW" badge dismissal (NOT per-profile —
    -- once a user has seen a feature, the badge stays gone everywhere)
    BossWatchDB.seenFeatures = BossWatchDB.seenFeatures or {}
end

function BossW:GetActiveProfileName()
    ensureProfilesDB()
    local key = BossW:GetCharKey()
    local n = BossWatchDB.charBindings[key]
    if n and BossWatchDB.profiles[n] then return n end
    BossWatchDB.charBindings[key] = "Default"
    return "Default"
end

function BossW:GetDB()
    ensureProfilesDB()
    local name = BossW:GetActiveProfileName()
    local p = BossWatchDB.profiles[name]
    migrateLegacyTextures(p)
    seedDefaults(p)
    return p
end

function BossW:SetActiveProfile(name)
    ensureProfilesDB()
    if not BossWatchDB.profiles[name] then return false end
    BossWatchDB.charBindings[BossW:GetCharKey()] = name
    if BossW.RefreshAll then BossW:RefreshAll() end
    if BossW.ApplyFonts then BossW:ApplyFonts() end
    return true
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = deepCopy(v) end
    return c
end

function BossW:CreateProfile(newName, copyFromName)
    ensureProfilesDB()
    if not newName or newName == "" or BossWatchDB.profiles[newName] then return false end
    local source = BossWatchDB.profiles[copyFromName or BossW:GetActiveProfileName()]
    BossWatchDB.profiles[newName] = source and deepCopy(source) or {}
    return true
end

function BossW:ResetProfile(name)
    ensureProfilesDB()
    if not BossWatchDB.profiles[name] then return false end
    BossWatchDB.profiles[name] = {}
    return true
end

function BossW:DeleteProfile(name)
    ensureProfilesDB()
    if name == "Default" then return false, "cannot delete Default" end
    if not BossWatchDB.profiles[name] then return false end
    BossWatchDB.profiles[name] = nil
    for k, v in pairs(BossWatchDB.charBindings) do
        if v == name then BossWatchDB.charBindings[k] = "Default" end
    end
    return true
end

function BossW:ListProfiles()
    ensureProfilesDB()
    local list = {}
    for n in pairs(BossWatchDB.profiles) do list[#list + 1] = n end
    table.sort(list, function(a, b)
        if a == "Default" then return true end
        if b == "Default" then return false end
        return a:lower() < b:lower()
    end)
    return list
end

-- ============================================================
-- BASE64 + SERIALIZE (for Export / Import)
-- ============================================================
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function b64encode(data)
    return ((data:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
        return B64:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

local function b64decode(data)
    data = string.gsub(data, '[^' .. B64 .. '=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (B64:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

local function serialize(t, indent)
    indent = indent or ""
    local typ = type(t)
    if typ == "string" then return string.format("%q", t) end
    if typ == "number" or typ == "boolean" then return tostring(t) end
    if typ ~= "table" then return "nil" end
    local parts = { "{\n" }
    local nextIndent = indent .. "  "
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
        local v = t[k]
        local key
        if type(k) == "string" and k:match("^[%a_][%w_]*$") then
            key = k
        elseif type(k) == "string" then
            key = "[" .. string.format("%q", k) .. "]"
        else
            key = "[" .. tostring(k) .. "]"
        end
        parts[#parts + 1] = nextIndent .. key .. " = " .. serialize(v, nextIndent) .. ",\n"
    end
    parts[#parts + 1] = indent .. "}"
    return table.concat(parts)
end

function BossW:ExportProfile(name)
    ensureProfilesDB()
    local p = BossWatchDB.profiles[name or BossW:GetActiveProfileName()]
    if not p then return nil end
    local body = "return " .. serialize(p)
    return "BW1:" .. b64encode(body)
end

function BossW:ImportProfile(text, newName, overwrite)
    if not text or text == "" then return false, "import box is empty" end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text:sub(1, 4) ~= "BW1:" then return false, "invalid format" end
    local body = b64decode(text:sub(5))
    if not body or body == "" then return false, "decode failed" end
    local fn, err = (loadstring or load)(body, "import", "t", {})
    if not fn then return false, tostring(err) end
    setfenv = setfenv or function() end
    pcall(setfenv, fn, {})
    local ok, profile = pcall(fn)
    if not ok or type(profile) ~= "table" then return false, "invalid table" end
    if not newName or newName == "" then return false, "missing name" end
    ensureProfilesDB()
    if BossWatchDB.profiles[newName] and not overwrite then
        return false, "profile already exists"
    end
    BossWatchDB.profiles[newName] = profile
    return true
end

-- ============================================================
-- TEXTURE RESOLUTION (no LSM dep — LSM optional)
-- ============================================================
-- Register our own modern Blizzard textures into LSM so they exist
-- regardless of which other addons are loaded.
do
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        LSM:Register("statusbar", "Blizzard Modern", [[Interface\TargetingFrame\UI-TargetingFrame-BarFill]])
    end
end

function BossW:ResolveTexture(name)
    if not name or name == "" then
        return "Interface\\TargetingFrame\\UI-StatusBar"
    end
    if name:find("\\") or name:find("/") then return name end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local p = LSM:Fetch("statusbar", name)
        if p then return p end
    end
    return "Interface\\TargetingFrame\\UI-StatusBar"
end

function BossW:ResolveFont(name)
    local fallback = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    if not name or name == "" then return fallback end
    if name:find("\\") or name:find("/") then return name end
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local p = LSM:Fetch("font", name)
        if p then return p end
    end
    return fallback
end

function BossW:ApplyFonts()
    if not BossW.BossFrames then return end
    local db = BossW:GetDB()
    local file = BossW:ResolveFont(db.fontFace)
    local size = db.fontSize or 12
    local outline = db.fontOutline or "NONE"
    if outline == "NONE" then outline = "" end

    local function setF(fs, sz, ol)
        if fs then pcall(fs.SetFont, fs, file, sz, ol) end
    end

    for i = 1, BossW.MAX_BOSS do
        local f = BossW.BossFrames[i]
        if f then
            setF(f.nameText,   size,     outline)
            setF(f.healthText, size,     outline)
            setF(f.powerText,  math.max(8, size - 2), outline)
            if f.castBar then
                setF(f.castBar.spellText, size, outline)
                setF(f.castBar.timeText,  size, outline)
            end
            if f._auras then
                local auraOutline = (outline == "" and "OUTLINE") or outline
                for _, a in ipairs(f._auras) do
                    setF(a.stacks, size, auraOutline)
                    setF(a.timer,  size, auraOutline)
                end
            end
        end
    end
end

-- ============================================================
-- LOCALIZATION (lazy, fallback returns the key)
-- ============================================================
BossW.L = setmetatable({}, { __index = function(t, k) return k end })

-- ============================================================
-- HIDE BLIZZARD BOSS FRAMES
-- ============================================================
local blizzardHidden = false
-- Hide Blizzard boss frames WITHOUT tainting them.
-- In WoW 12.0+, overriding `frame.Show = function() end` or calling
-- `UnregisterAllEvents()` on a secure Blizzard frame taints that frame and
-- every child. The taint then cascades through EditMode (RefreshArenaFrames
-- → CastingBarFrame:StopFinishAnims iterates a now-<forbidden table>) and
-- spams "execution tainted by 'BossWatch'" the moment the user opens EditMode.
-- Safe approach: move the frames off-screen and disable mouse — visually gone,
-- secure methods untouched.
local function _hideSecure(f)
    if not f then return end
    f:SetAlpha(0)
    if f.EnableMouse then f:EnableMouse(false) end
    if f.ClearAllPoints then f:ClearAllPoints() end
    if f.SetPoint then f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -10000, -10000) end
end

local function _eachBlizzardBossFrame(fn)
    fn(_G["BossTargetFrameContainer"] or _G["BossFrameContainer"])
    for i = 1, BossW.MAX_BOSS do
        for _, n in ipairs({ "Boss" .. i .. "TargetFrame", "BossTargetFrame" .. i }) do
            fn(_G[n])
        end
    end
end

function BossW:HideBlizzardBossFrames()
    if blizzardHidden then return end
    if InCombatLockdown() then
        -- Reload-in-combat: ClearAllPoints/SetPoint on Blizzard's protected
        -- boss frames are blocked. SetAlpha is NOT — apply that now so the
        -- frames at least vanish visually, flag the full hide as pending,
        -- and DON'T latch blizzardHidden (the PLAYER_REGEN_ENABLED handler
        -- in Frames/Boss.lua re-invokes us on a clean stack).
        BossW._blizzHidePending = true
        _eachBlizzardBossFrame(function(f) if f then f:SetAlpha(0) end end)
        return
    end
    blizzardHidden = true
    BossW._blizzHidePending = nil
    _eachBlizzardBossFrame(_hideSecure)
end

-- ============================================================
-- SLASH COMMAND
-- ============================================================
SLASH_BOSSWATCH1 = "/bossw"
SLASH_BOSSWATCH2 = "/bosswatch"
SlashCmdList["BOSSWATCH"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" or msg == "config" or msg == "options" then
        if BossW.ToggleOptions then BossW:ToggleOptions() end
        return
    end
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    if cmd == "test" then
        if BossW.SetTestMode then BossW:SetTestMode(tonumber(arg) or 5) end
    elseif cmd == "mover" then
        if BossW.ToggleMover then BossW:ToggleMover() end
    elseif cmd == "reset" then
        BossWatchDB = nil
        ReloadUI()
    elseif cmd == "auras" then
        BossW:DumpAuras(arg ~= "" and arg or nil)
    else
        local L = BossW.L
        print("|cffeda55fBossWatch:|r " .. L["commands:"])
        print("  /bossw            - " .. L["open options"])
        print("  /bossw mover      - " .. L["toggle mover"])
        print("  /bossw test N     - " .. L["simulate N bosses (0-5)"])
        print("  /bossw auras [unit] - " .. L["dump auras on bosses (or given unit) showing which fields are secret-tagged"])
        print("  /bossw reset      - " .. L["reset all settings + reload"])
    end
end

-- ============================================================
-- AURA DEBUG DUMP
-- Print every aura on each boss unit with per-field secret-status,
-- so the user can see exactly which data Blizzard exposes vs redacts
-- on hostile bosses in 12.0+.
-- ============================================================
local issecretvalue = _G.issecretvalue or function() return false end

local function _fieldStr(value)
    if value == nil then return "|cff666666nil|r" end
    if issecretvalue(value) then return "|cffff5555[secret]|r" end
    local ok, str = pcall(tostring, value)
    if ok and str then return "|cff66ff66" .. str .. "|r" end
    return "|cffff5555[unprintable]|r"
end

local function _dumpAura(unit, i, filter)
    local data
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        data = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
    end
    if not data then
        local name, icon, count, _, duration, expiration, caster = UnitAura(unit, i, filter)
        if not name then return false end
        data = {
            name = name, icon = icon, applications = count,
            duration = duration, expirationTime = expiration,
            sourceUnit = caster,
        }
    end
    print(format("  [%d] name=%s  icon=%s  stacks=%s  duration=%s  expires=%s",
        i, _fieldStr(data.name), _fieldStr(data.icon),
        _fieldStr(data.applications), _fieldStr(data.duration),
        _fieldStr(data.expirationTime)))
    print(format("       source=%s  isBoss=%s  isPlayer=%s  spellId=%s",
        _fieldStr(data.sourceUnit), _fieldStr(data.isBossAura),
        _fieldStr(data.isFromPlayerOrPlayerPet), _fieldStr(data.spellId)))
    return true
end

function BossW:DumpAuras(unit)
    local units
    if unit then
        units = { unit }
    else
        units = {}
        for i = 1, BossW.SlotProvider:GetMaxSlots() do
            local u = BossW.SlotProvider:GetUnit(i)
            if u and UnitExists(u) then units[#units + 1] = u end
        end
        if #units == 0 then units = { "target" } end
    end
    for _, u in ipairs(units) do
        if UnitExists(u) then
            local n = UnitName(u)
            print(format("|cffeda55f== %s (%s) ==|r", _fieldStr(n), u))
            for _, filter in ipairs({ "HARMFUL", "HELPFUL" }) do
                print(format("|cffaaaaaa-- %s --|r", filter))
                local found = false
                for i = 1, 40 do
                    if not _dumpAura(u, i, filter) then break end
                    found = true
                end
                if not found then print("  |cff666666(none)|r") end
            end
        else
            print(format("|cffeda55fBossWatch:|r unit '%s' does not exist", u))
        end
    end
end

-- ============================================================
-- INIT
-- ============================================================
local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
function BossW:RegisterMinimapIcon()
    if BossW._minimapRegistered then return end
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not LDB or not Icon then return end

    local broker = LDB:NewDataObject("BossWatch", {
        type = "launcher",
        text = "BossWatch",
        icon = "Interface\\AddOns\\BossWatch\\Media\\minimap.png",
        OnClick = function(_, button)
            if button == "RightButton" then
                if BossW.ToggleMover then BossW:ToggleMover() end
            else
                if BossW.ToggleOptions then BossW:ToggleOptions() end
            end
        end,
        OnTooltipShow = function(tip)
            tip:AddLine("|cffeda55fBossWatch|r")
            tip:AddLine("|cffaaaaaa" .. (BossW.L["left-click: options"] or "left-click: options") .. "|r")
            tip:AddLine("|cffaaaaaa" .. (BossW.L["right-click: toggle mover"] or "right-click: toggle mover") .. "|r")
        end,
    })
    Icon:Register("BossWatch", broker, BossWatchDB.minimap)
    BossW._minimapRegistered = true
end

function BossW:ToggleMinimapIcon(show)
    BossWatchDB.minimap = BossWatchDB.minimap or { hide = true }
    BossWatchDB.minimap.hide = not show
    local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
    if Icon then
        if show then Icon:Show("BossWatch") else Icon:Hide("BossWatch") end
    end
end

init:SetScript("OnEvent", function()
    BossW:GetDB()
    if BossW.EnsureCreated then BossW:EnsureCreated() end
    if BossW.ApplyFonts then BossW:ApplyFonts() end
    if BossW.RegisterMinimapIcon then BossW:RegisterMinimapIcon() end
    if BossW.RegisterBlizzardSettings then BossW:RegisterBlizzardSettings() end
    local v = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
    print(format("|cffeda55fBossWatch|r v%s " .. (BossW.L["loaded"] or "loaded") ..
        " — |cffffff00/bossw|r " .. (BossW.L["(options)"] or "(options)") ..
        ", |cffffff00/bossw test 5|r " .. (BossW.L["(preview)"] or "(preview)") ..
        ", |cffffff00/bossw mover|r " .. (BossW.L["(move frames)"] or "(move frames)"), v))
end)
