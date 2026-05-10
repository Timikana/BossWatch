local addonName, BossW = ...

local pairs, ipairs, format = pairs, ipairs, string.format
local CreateFrame = CreateFrame
local UnitExists, UnitName, UnitClass = UnitExists, UnitName, UnitClass
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitPower, UnitPowerMax, UnitPowerType = UnitPower, UnitPowerMax, UnitPowerType
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local SetPortraitTexture = SetPortraitTexture
local InCombatLockdown = InCombatLockdown
local AbbreviateLargeNumbers = AbbreviateLargeNumbers or tostring
local issecretvalue = _G.issecretvalue or function() return false end

-- Format a NUMBER (non-secret) according to scale. Returns string.
-- For secret values, returns nil — caller must fall back to SetFormattedText("%s", secret).
local function formatNumber(value, mode)
    if value == nil then return nil end
    if issecretvalue(value) then return nil end
    if type(value) ~= "number" then return tostring(value) end

    mode = mode or "AUTO"
    if mode == "RAW" then return format("%d", value) end
    if mode == "K"   then return format("%.0fK", value / 1e3) end
    if mode == "M"   then return format("%.1fM", value / 1e6) end
    if mode == "G"   then return format("%.2fB", value / 1e9) end
    -- AUTO: pick the magnitude that gives a readable value
    if mode == "AUTO" then
        local v = value
        if v < 0 then v = -v end
        if     v >= 1e9 then return format("%.2fB", value / 1e9)
        elseif v >= 1e6 then return format("%.1fM", value / 1e6)
        elseif v >= 1e4 then return format("%.0fK", value / 1e3)
        else return format("%d", value) end
    end
    return format("%d", value)
end

-- Brute-force attempt: wrap EVERYTHING in pcall. If anywhere along the way
-- a secret-string operation throws, we silently fail and return nil. Caller
-- falls back to %s passthrough. This may succeed on some hostile bosses
-- where Blizzard's __tostring happens to yield a non-secret string.
local function tryAbbreviateSecret(value, mode)
    local ok, result = pcall(function()
        local s = format("%s", value)
        if not s or s == "" then return nil end
        local clean = s:gsub("[%s,]", "")
        local digits, suffix = clean:match("^(%d+%.?%d*)([KkMmBbGgTt]?)$")
        if not digits then return nil end
        local n = tonumber(digits)
        if not n then return nil end
        local mult = 1
        if     suffix == "K" or suffix == "k" then mult = 1e3
        elseif suffix == "M" or suffix == "m" then mult = 1e6
        elseif suffix == "B" or suffix == "b" or suffix == "G" or suffix == "g" then mult = 1e9
        end
        n = n * mult

        if     mode == "K"    then return format("%.0fK", n / 1e3)
        elseif mode == "M"    then return format("%.1fM", n / 1e6)
        elseif mode == "G"    then return format("%.2fB", n / 1e9)
        elseif mode == "AUTO" then
            if     n >= 1e9 then return format("%.2fB", n / 1e9)
            elseif n >= 1e6 then return format("%.1fM", n / 1e6)
            elseif n >= 1e4 then return format("%.0fK", n / 1e3)
            else return format("%d", n) end
        elseif mode == "RAW"  then return s end
        return nil
    end)
    if ok then return result end
    return nil
end

-- Re-format the text already set on a FontString according to mode. Used
-- after SetFormattedText("%s", secret) — sometimes Blizzard's render path
-- untaints the result, letting us read GetText() and re-format.
local function tryReformatFontString(fontString, mode)
    if mode == "RAW" or not mode then return end
    local ok, txt = pcall(fontString.GetText, fontString)
    if not ok or not txt or issecretvalue(txt) then return end
    -- Match number with optional K/M/B suffix, possibly with surrounding text
    local pre, digits, suffix, post = txt:match("^(.-)(%d[%d,%.]*)([KkMmBbGgTt]?)(.*)$")
    if not digits then return end
    local clean = digits:gsub(",", "")
    local n = tonumber(clean)
    if not n then return end
    local mult = 1
    if     suffix == "K" or suffix == "k" then mult = 1e3
    elseif suffix == "M" or suffix == "m" then mult = 1e6
    elseif suffix == "B" or suffix == "b" or suffix == "G" or suffix == "g" then mult = 1e9
    end
    n = n * mult
    local formatted
    if     mode == "K"    then formatted = format("%.0fK", n / 1e3)
    elseif mode == "M"    then formatted = format("%.1fM", n / 1e6)
    elseif mode == "G"    then formatted = format("%.2fB", n / 1e9)
    elseif mode == "AUTO" then
        if     n >= 1e9 then formatted = format("%.2fB", n / 1e9)
        elseif n >= 1e6 then formatted = format("%.1fM", n / 1e6)
        elseif n >= 1e4 then formatted = format("%.0fK", n / 1e3)
        else formatted = format("%d", n) end
    end
    if formatted then
        fontString:SetText((pre or "") .. formatted .. (post or ""))
    end
end

local function setNumberText(fontString, value, mode)
    if value == nil then fontString:SetText(""); return end
    if issecretvalue(value) then
        -- Step 1: try parse+reformat from %s output before setting text
        local txt = tryAbbreviateSecret(value, mode)
        if txt then fontString:SetText(txt); return end
        -- Step 2: pass secret to FontString — Blizzard renders, then we re-read
        -- the rendered text and reformat if it's no longer tainted.
        pcall(fontString.SetFormattedText, fontString, "%s", value)
        tryReformatFontString(fontString, mode)
        return
    end
    fontString:SetText(formatNumber(value, mode) or "")
end

local MAX_BOSS = BossW.MAX_BOSS

local CLASS_COLORS = RAID_CLASS_COLORS or {}

-- ============================================================
-- COLORS
-- ============================================================
local function GetHealthColor(db, unit)
    local mode = db.healthColorMode or "REACTION"
    if mode == "STATIC" then
        local c = db.healthStaticColor; return c.r, c.g, c.b
    elseif mode == "REACTION" then
        local r = UnitReaction and UnitReaction(unit, "player")
        if r and FACTION_BAR_COLORS and FACTION_BAR_COLORS[r] then
            local c = FACTION_BAR_COLORS[r]; return c.r, c.g, c.b
        end
        return 0.9, 0.15, 0.15
    end
    local _, cls = UnitClass(unit)
    local cc = cls and CLASS_COLORS[cls]
    if cc then return cc.r, cc.g, cc.b end
    return 0.9, 0.15, 0.15
end

local function GetPowerColor(unit)
    local _, token = UnitPowerType(unit)
    local info = token and PowerBarColor and PowerBarColor[token]
    if info then return info.r, info.g, info.b end
    return 0.3, 0.4, 0.9
end

-- ============================================================
-- HEALTH / POWER UPDATES (secret-value safe)
-- ============================================================
local function GetSafeHealthPercent(unit)
    if UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
        return UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
    end
    local hp = UnitHealth(unit)
    local hpMax = UnitHealthMax(unit)
    if type(hp) ~= "number" or type(hpMax) ~= "number" or hpMax == 0 then return 100 end
    return (hp / hpMax) * 100
end

-- Smoothly drive a StatusBar towards `target`. When the user has disabled
-- smoothing (or the value isn't a plain number), set immediately. The
-- interpolation runs in the bar's own OnUpdate so it auto-stops when the
-- frame is hidden.
local function SmoothSetValue(bar, target)
    local db = BossW:GetDB()
    if not db.smoothBars or type(target) ~= "number" then
        bar:SetScript("OnUpdate", nil)
        bar._smoothing = false
        bar:SetValue(target or 0)
        return
    end
    bar._smoothTarget = target
    if bar._smoothing then return end
    bar._smoothing = true
    bar:SetScript("OnUpdate", function(self, dt)
        local cur = self:GetValue() or 0
        local t = self._smoothTarget or cur
        local diff = t - cur
        if math.abs(diff) < 0.4 then
            self:SetValue(t)
            self:SetScript("OnUpdate", nil)
            self._smoothing = false
            return
        end
        -- Ease out: cover ~8x dt of the remaining distance per frame
        self:SetValue(cur + diff * math.min(1, dt * 8))
    end)
end

local function SetHealthValue(frame, unit)
    local pct = GetSafeHealthPercent(unit)
    frame.healthBar:SetMinMaxValues(0, 100)
    SmoothSetValue(frame.healthBar, pct or 0)
    frame._hpPct = pct or 0
end

-- Restored from v0.4.8 — relies on pcall + AbbreviateLargeNumbers passthrough.
-- On hostile bosses the secret-value crash inside AbbreviateLargeNumbers is
-- caught silently and Blizzard's __tostring path fills the FontString instead.
local function SetPowerValue(frame, unit)
    if not frame.powerBar or not frame.powerBar:IsShown() then return end
    local okP, p = pcall(UnitPower, unit)
    local okM, pMax = pcall(UnitPowerMax, unit)
    if not okP or not okM then return end
    local okCmp, hasPower = pcall(function() return pMax and pMax > 0 end)
    if okCmp and not hasPower then
        frame.powerBar:Hide()
        if frame.powerText then frame.powerText:SetText("") end
        return
    end
    frame.powerBar:Show()
    pcall(frame.powerBar.SetMinMaxValues, frame.powerBar, 0, pMax)
    pcall(frame.powerBar.SetValue, frame.powerBar, p)
    frame.powerBar:SetStatusBarColor(GetPowerColor(unit))

    if not frame.powerText then return end
    local db = BossW:GetDB()
    if not db.showPowerText then frame.powerText:SetText(""); return end

    local function visualPct()
        local tex = frame.powerBar:GetStatusBarTexture()
        local barW = frame.powerBar:GetWidth()
        if not tex or not barW or barW <= 0 then return 0 end
        local ok, w = pcall(tex.GetWidth, tex)
        if not ok or not w then return 0 end
        local ok2, pct = pcall(function() return (w or 0) / barW * 100 end)
        if ok2 then return pct end
        return 0
    end

    -- Strip optional ".SCALE" suffix (e.g. "CURRENT.RAW" → "CURRENT")
    local rawFmt = db.powerTextFormat or "PERCENT"
    local fmt = rawFmt:match("^([^%.]+)") or rawFmt
    if fmt == "PERCENT" then
        frame.powerText:SetFormattedText("%d%%", visualPct())
    elseif fmt == "CURRENT" then
        pcall(frame.powerText.SetText, frame.powerText, AbbreviateLargeNumbers(p))
    elseif fmt == "CURRENT_PERCENT" then
        local okAbbr, pStr = pcall(AbbreviateLargeNumbers, p)
        if okAbbr then frame.powerText:SetFormattedText("%s (%d%%)", pStr, visualPct())
        else frame.powerText:SetFormattedText("%d%%", visualPct()) end
    elseif fmt == "CURRENT_MAX" then
        pcall(frame.powerText.SetFormattedText, frame.powerText,
            "%s / %s", AbbreviateLargeNumbers(p), AbbreviateLargeNumbers(pMax))
    elseif fmt == "RAW" then
        pcall(frame.powerText.SetFormattedText, frame.powerText, "%s", p)
    end
end

-- Parse a format value like "CURRENT.AUTO" into ("CURRENT", "AUTO").
-- Backwards compat: bare "CURRENT" → ("CURRENT", "AUTO").
local function parseFormat(fmt)
    if not fmt or fmt == "" then return "PERCENT", "AUTO" end
    local kind, scale = fmt:match("^([^%.]+)%.(.+)$")
    if not kind then return fmt, "AUTO" end
    return kind, scale
end

-- v0.4.8 restored: relies on pcall + AbbreviateLargeNumbers passthrough.
-- The Blizzard internal __tostring path renders K/M for valid magnitudes.
local function FormatHealthText(frame, db, unit)
    if not frame.healthText then return end
    if not db.showHealthText then frame.healthText:SetText(""); return end
    -- Strip optional ".SCALE" suffix from legacy values like "CURRENT.RAW"
    local fmt = (db.healthTextFormat or "PERCENT"):match("^([^%.]+)") or "PERCENT"
    local pct = frame._hpPct or 0
    if fmt == "PERCENT" then
        pcall(frame.healthText.SetFormattedText, frame.healthText, "%d%%", pct)
    elseif fmt == "RAW" then
        if frame._testMode then
            frame.healthText:SetText(format("%d", (frame._testHp or 0) * 1e6))
        else
            local ok, hp = pcall(UnitHealth, unit)
            if ok then pcall(frame.healthText.SetFormattedText, frame.healthText, "%s", hp) end
        end
    elseif fmt == "CURRENT" then
        if frame._testMode then
            frame.healthText:SetText(AbbreviateLargeNumbers((frame._testHp or 0) * 1e6))
        else
            local ok, hp = pcall(UnitHealth, unit)
            if ok and type(hp) == "number" then
                frame.healthText:SetText(AbbreviateLargeNumbers(hp))
            else
                pcall(frame.healthText.SetText, frame.healthText, AbbreviateLargeNumbers(hp))
            end
        end
    elseif fmt == "CURRENT_PERCENT" then
        if frame._testMode then
            local hp = (frame._testHp or 0) * 1e6
            frame.healthText:SetFormattedText("%s (%d%%)", AbbreviateLargeNumbers(hp), pct)
        else
            local ok, hp = pcall(UnitHealth, unit)
            if ok and type(hp) == "number" then
                pcall(frame.healthText.SetFormattedText, frame.healthText, "%s (%d%%)", AbbreviateLargeNumbers(hp), pct)
            else
                pcall(frame.healthText.SetFormattedText, frame.healthText, "%s (%d%%)", AbbreviateLargeNumbers(hp), pct)
            end
        end
    end
end

-- ============================================================
-- FRAME UPDATE
-- ============================================================
local TEST_CLASSES = { "WARRIOR", "MAGE", "WARLOCK", "DEATHKNIGHT", "DEMONHUNTER" }

local function getHighlightColor(frame)
    local db = BossW:GetDB()
    local mode = db.targetHighlightColorMode or "STATIC"
    local fallback = db.targetHighlightColor or { r = 1, g = 0.82, b = 0, a = 1 }
    local a = fallback.a or 1
    local unit = frame and frame.unit
    local isTest = frame and frame._testMode

    if mode == "CLASS" then
        local cls
        if isTest then
            cls = TEST_CLASSES[(frame.index - 1) % #TEST_CLASSES + 1]
        elseif unit then
            local _, c = UnitClass(unit)
            if c and not issecretvalue(c) then cls = c end
        end
        if cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls] then
            local c = RAID_CLASS_COLORS[cls]
            return c.r, c.g, c.b, a
        end
    elseif mode == "REACTION" then
        if isTest then
            return 1, 0.2, 0.2, a -- bosses are hostile in test mode
        end
        local reaction
        if unit then
            local r = UnitReaction("player", unit)
            if r and not issecretvalue(r) then reaction = r end
        end
        if reaction then
            if reaction >= 5 then return 0.2, 1, 0.2, a end       -- friendly
            if reaction == 4 then return 1, 1, 0.2, a end          -- neutral
            return 1, 0.2, 0.2, a                                  -- hostile
        end
    end
    return fallback.r, fallback.g, fallback.b, a
end

local function applyTargetHighlight(frame)
    local hl = frame and frame.targetHighlight
    if not hl then return end
    local db = BossW:GetDB()
    if not db.targetHighlight then
        if hl._anim then hl._anim:Stop() end
        hl:Hide()
        return
    end
    local thick = db.targetHighlightThickness or 2
    hl:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = thick,
    })
    local r, g, b, a = getHighlightColor(frame)
    hl:SetBackdropBorderColor(r, g, b, a)
    local isTarget = false
    if frame._fakeTarget then
        isTarget = true
    else
        local v = UnitIsUnit("target", frame.unit)
        if v ~= nil and not issecretvalue(v) then isTarget = v == true end
    end
    if isTarget and frame:IsShown() then
        hl:SetAlpha(1)
        hl:Show()
        if db.targetHighlightAnimate and hl._anim then
            if not hl._anim:IsPlaying() then hl._anim:Play() end
        elseif hl._anim then
            hl._anim:Stop()
        end
    else
        if hl._anim then hl._anim:Stop() end
        hl:Hide()
    end
end
BossW._applyTargetHighlight = applyTargetHighlight

local function UpdateFrame(frame)
    local unit = frame.unit
    local db = BossW:GetDB()

    -- Visibility driven by RegisterStateDriver — don't Show/Hide here.

    -- Name. Visual-width truncation via SetWidth works for both regular strings
    -- and secret-tagged values (the renderer handles them internally).
    if frame.nameText then
        if db.showName then
            local n = UnitName(unit) or frame._testName or ("Boss " .. (frame.index or "?"))
            frame.nameText:SetWordWrap(false)
            frame.nameText:SetMaxLines(1)
            local maxLen = db.nameMaxLength or 0
            if maxLen > 0 then
                frame.nameText:SetWidth(maxLen * 7)
            elseif db.layoutBlocks == 4 then
                frame.nameText:SetWidth((frame.healthBar and frame.healthBar:GetWidth() or 200) - 8)
            else
                frame.nameText:SetWidth(0)
            end
            frame.nameText:SetText(n)
        else
            frame.nameText:SetText("")
        end
    end

    -- Portrait (2D)
    if frame.portrait then
        if db.portraitPosition ~= "HIDDEN" then
            frame.portrait:Show()
            if frame._testMode then
                local TEST_PORTRAITS = {
                    "Interface\\Icons\\Achievement_Boss_LichKing",
                    "Interface\\Icons\\Achievement_Boss_KelThuzad_01",
                    "Interface\\Icons\\Achievement_Boss_Onyxia",
                    "Interface\\Icons\\Achievement_Boss_Ragnaros",
                    "Interface\\Icons\\Achievement_Boss_Illidan",
                }
                frame.portrait:SetTexture(TEST_PORTRAITS[frame.index] or TEST_PORTRAITS[1])
            else
                SetPortraitTexture(frame.portrait, unit)
            end
        else
            frame.portrait:Hide()
        end
    end

    -- Health
    if frame._testMode then
        frame.healthBar:SetMinMaxValues(0, 100)
        SmoothSetValue(frame.healthBar, frame._testHp or 80)
        frame._hpPct = frame._testHp or 80
    else
        SetHealthValue(frame, unit)
    end
    frame.healthBar:SetStatusBarColor(GetHealthColor(db, unit))

    -- Absorb (TankWatch pattern): SetMinMax(0, hpMax) + SetValue(absorbAmount)
    -- with SetReverseFill(true) → fills from the right edge by absorb/hpMax.
    if frame.absorbBar then
        if not db.showAbsorbs then
            frame.absorbBar:Hide()
        elseif frame._testMode then
            local absAmount = frame._testAbsorb or 25
            frame.absorbBar:SetMinMaxValues(0, 100)
            frame.absorbBar:SetValue(absAmount)
            frame.absorbBar:Show()
        else
            local max = UnitHealthMax(unit)
            local absAmount
            pcall(function() absAmount = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) end)
            local maxSecret = issecretvalue(max)
            if not maxSecret and (not max or max <= 0) then
                frame.absorbBar:Hide()
            else
                local hasAbs = false
                if issecretvalue(absAmount) then hasAbs = true
                elseif absAmount and absAmount > 0 then hasAbs = true end
                if not hasAbs then
                    frame.absorbBar:Hide()
                else
                    frame.absorbBar:SetMinMaxValues(0, max)
                    pcall(frame.absorbBar.SetValue, frame.absorbBar, absAmount)
                    frame.absorbBar:Show()
                end
            end
        end
    end

    -- Power
    if db.showPowerBar and frame.powerBar then
        frame.powerBar:Show()
        if frame._testMode then
            local pPct = frame._testPower or 50
            frame.powerBar:SetMinMaxValues(0, 100)
            frame.powerBar:SetValue(pPct)
            -- Power types per test boss, themed to match lore:
            -- 1 Lich King = Runic Power (cyan death-knight)
            -- 2 Kel'Thuzad = Mana (lich/caster blue)
            -- 3 Onyxia = Rage (dragon fury red)
            -- 4 Ragnaros = Energy (fire-yellow)
            -- 5 Illidan = Fury (demon hunter purple)
            local TEST_POWER_COLORS = {
                [1] = { 0.00, 0.85, 0.95 },  -- runic power
                [2] = { 0.30, 0.45, 1.00 },  -- mana
                [3] = { 1.00, 0.20, 0.20 },  -- rage
                [4] = { 1.00, 0.95, 0.40 },  -- energy
                [5] = { 0.65, 0.30, 1.00 },  -- fury
            }
            local c = TEST_POWER_COLORS[frame.index] or { 0.3, 0.4, 0.9 }
            frame.powerBar:SetStatusBarColor(c[1], c[2], c[3])
            if frame.powerText then
                if db.showPowerText then
                    -- Fake mana values for test: 100% = 250k mana
                    local fakeMax = 250000
                    local fakeCur = math.floor(fakeMax * pPct / 100)
                    local rawFmt = db.powerTextFormat or "PERCENT"
                    local fmt = rawFmt:match("^([^%.]+)") or rawFmt
                    if fmt == "PERCENT" then
                        frame.powerText:SetFormattedText("%d%%", pPct)
                    elseif fmt == "CURRENT" or fmt == "RAW" then
                        frame.powerText:SetText(AbbreviateLargeNumbers(fakeCur))
                    elseif fmt == "CURRENT_PERCENT" then
                        frame.powerText:SetFormattedText("%s (%d%%)", AbbreviateLargeNumbers(fakeCur), pPct)
                    else
                        frame.powerText:SetFormattedText("%s / %s",
                            AbbreviateLargeNumbers(fakeCur), AbbreviateLargeNumbers(fakeMax))
                    end
                else frame.powerText:SetText("") end
            end
        else
            SetPowerValue(frame, unit)
        end
    elseif frame.powerBar then
        frame.powerBar:Hide()
    end

    FormatHealthText(frame, db, unit)

    -- Dead overlay
    if (not frame._testMode) and UnitIsDeadOrGhost(unit) then
        frame:SetAlpha(0.4)
    else
        frame:SetAlpha(1)
    end

    -- Raid target icon
    if db.showRaidTargetIcon and BossW.UpdateRaidTargetIcon then
        BossW.UpdateRaidTargetIcon(frame)
    elseif frame.raidTargetIcon then
        frame.raidTargetIcon:Hide()
    end

    -- Auras
    if BossW.UpdateAuras then BossW.UpdateAuras(frame) end

    -- Target highlight border
    applyTargetHighlight(frame)
end
BossW.UpdateFrame = UpdateFrame

-- ============================================================
-- RAID TARGET ICON
-- ============================================================
function BossW.UpdateRaidTargetIcon(frame)
    if not frame.raidTargetIcon then return end
    local unit = frame.unit
    local idx
    if frame._testMode then
        idx = frame.index
    else
        idx = GetRaidTargetIndex(unit)
    end
    if not idx or issecretvalue(idx) or idx == 0 then
        frame.raidTargetIcon:Hide()
        return
    end
    if SetRaidTargetIconTexCoord then
        SetRaidTargetIconTexCoord(frame.raidTargetIcon, idx)
    elseif SetRaidTargetIconTexture then
        SetRaidTargetIconTexture(frame.raidTargetIcon, idx)
    end
    frame.raidTargetIcon:Show()
end

-- ============================================================
-- LAYOUT
-- ============================================================
local _pendingLayout = false

local VALID_ANCHOR9 = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}
local function justifyOf(anchor)
    if anchor:find("LEFT") then return "LEFT"
    elseif anchor:find("RIGHT") then return "RIGHT"
    else return "CENTER" end
end

local function ApplyLayout()
    local db = BossW:GetDB()
    local container = BossW.BossContainer
    if not container then return end

    if InCombatLockdown() then _pendingLayout = true; return end

    container:SetScale(db.frameScale or 1)
    container:SetFrameStrata(db.frameStrata or "MEDIUM")

    local anchor = db.anchor or "RIGHT"
    container:ClearAllPoints()
    container:SetPoint(anchor, UIParent, anchor, db.anchorX or 0, db.anchorY or 0)

    local hpTex = BossW:ResolveTexture(db.healthTexture)
    local pwTex = BossW:ResolveTexture(db.powerTexture or db.healthTexture)

    for i = 1, MAX_BOSS do
        local f = BossW.BossFrames[i]
        if not f then break end

        f:SetSize(db.frameWidth, db.frameHeight)
        f:ClearAllPoints()
        if i == 1 then
            f:SetPoint("TOP", container, "TOP", 0, 0)
        else
            local prev = BossW.BossFrames[i - 1]
            local s = db.frameSpacing
            if db.growDirection == "UP" then
                f:SetPoint("BOTTOM", prev, "TOP", 0, s)
            else
                f:SetPoint("TOP", prev, "BOTTOM", 0, -s)
            end
        end

        local bgTex = BossW:ResolveTexture(db.barBackgroundTexture or "Solid")
        if f.healthBar then
            f.healthBar:SetStatusBarTexture(hpTex)
            if f.healthBar.bg then
                f.healthBar.bg:SetTexture(bgTex)
                f.healthBar.bg:SetVertexColor(0.1, 0.1, 0.1, db.healthBackgroundAlpha or 0.35)
            end
        end
        if f.absorbBar then
            f.absorbBar:SetStatusBarTexture(BossW:ResolveTexture(db.absorbTexture or "Blizzard Raid Bar"))
            local c = db.absorbColor or { r = 1, g = 0xEB/0xFF, b = 0x3E/0xFF, a = 0x80/0xFF }
            f.absorbBar:SetStatusBarColor(c.r or 1, c.g or 0xEB/0xFF, c.b or 0x3E/0xFF, c.a or 0x80/0xFF)
        end
        if f.powerBar then
            f.powerBar:SetStatusBarTexture(pwTex)
            if f.powerBar.bg then
                f.powerBar.bg:SetTexture(bgTex)
                f.powerBar.bg:SetVertexColor(0, 0, 0, db.powerBackgroundAlpha or 0.7)
            end
        end
        -- Frame-level bg also uses the chosen texture
        if f.bg then
            f.bg:SetTexture(bgTex)
            f.bg:SetVertexColor(0, 0, 0, db.frameBackgroundAlpha or 0.6)
        end

        -- Portrait
        if f.portrait then
            local size = db.portraitSize
            f.portrait:SetSize(size, size)
            f.portrait:ClearAllPoints()
            if db.portraitPosition == "LEFT" then
                f.portrait:SetPoint("RIGHT", f, "LEFT", -2, 0)
            elseif db.portraitPosition == "RIGHT" then
                f.portrait:SetPoint("LEFT", f, "RIGHT", 2, 0)
            end
            if f.portraitBorder then
                f.portraitBorder:ClearAllPoints()
                if db.portraitPosition == "HIDDEN" then
                    f.portraitBorder:Hide()
                else
                    f.portraitBorder:Show()
                    f.portraitBorder:SetPoint("TOPLEFT", f.portrait, "TOPLEFT", -1, 1)
                    f.portraitBorder:SetPoint("BOTTOMRIGHT", f.portrait, "BOTTOMRIGHT", 1, -1)
                end
            end
        end

        -- Order: HP (top) → Power (mid) → Cast (bottom, integrated)
        local castH = (db.showCastBar and not db.castBarDetached) and (db.castBarHeight + 1) or 0
        local powerH = db.showPowerBar and (db.powerBarHeight + 1) or 0

        if f.powerBar then
            f.powerBar:ClearAllPoints()
            f.powerBar:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  0, castH)
            f.powerBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, castH)
            f.powerBar:SetHeight(db.powerBarHeight)
        end

        -- 4-block layout reserves a dedicated name row above the HP bar
        local nameRowH = (db.layoutBlocks == 4) and 16 or 0

        f.healthBar:ClearAllPoints()
        f.healthBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -nameRowH)
        f.healthBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -nameRowH)
        f.healthBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, castH + powerH)
        f.healthBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, castH + powerH)

        -- Power text anchor
        if f.powerText then
            f.powerText:ClearAllPoints()
            local a = db.powerTextAnchor
            if not VALID_ANCHOR9[a] then a = "RIGHT"; db.powerTextAnchor = a end
            f.powerText:SetPoint(a, f.powerBar, a, db.powerTextX or 0, db.powerTextY or 0)
            f.powerText:SetJustifyH(justifyOf(a))
            if db.showPowerText and db.showPowerBar then f.powerText:Show() else f.powerText:Hide() end
        end

        -- Name & health text
        if f.nameText then
            f.nameText:ClearAllPoints()
            if db.layoutBlocks == 4 then
                -- Dedicated row above the HP bar, single CENTER anchor so SetWidth works
                f.nameText:SetPoint("BOTTOM", f.healthBar, "TOP", 0, 1)
                f.nameText:SetJustifyH("CENTER")
            else
                local a = db.nameAnchor
                if not VALID_ANCHOR9[a] then a = "LEFT"; db.nameAnchor = a end
                f.nameText:SetPoint(a, f.healthBar, a, db.nameX or 0, db.nameY or 0)
                f.nameText:SetJustifyH(justifyOf(a))
            end
        end
        if f.healthText then
            f.healthText:ClearAllPoints()
            local a = db.healthTextAnchor
            if not VALID_ANCHOR9[a] then a = "RIGHT"; db.healthTextAnchor = a end
            f.healthText:SetPoint(a, f.healthBar, a, db.healthTextX or 0, db.healthTextY or 0)
            f.healthText:SetJustifyH(justifyOf(a))
        end

        -- Raid target icon
        if f.raidTargetIcon then
            if db.showRaidTargetIcon then
                local a = db.raidTargetAnchor
                if not VALID_ANCHOR9[a] then a = "CENTER"; db.raidTargetAnchor = a end
                f.raidTargetIcon:SetSize(db.raidTargetSize or 28, db.raidTargetSize or 28)
                f.raidTargetIcon:ClearAllPoints()
                f.raidTargetIcon:SetPoint(a, f, a, db.raidTargetX or 0, db.raidTargetY or 0)
                f.raidTargetIcon:SetAlpha(db.raidTargetAlpha or 0.9)
                if not f.raidTargetIcon:GetTexture() then
                    f.raidTargetIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
                end
            else
                f.raidTargetIcon:Hide()
            end
        end

        if BossW.LayoutCastBar then BossW.LayoutCastBar(f, db) end
        if BossW.LayoutAuras then BossW.LayoutAuras(f, db) end
        if BossW._updateFrameBg then BossW._updateFrameBg(f) end
    end

    -- Keep mover overlay in sync with portrait offsets if it's visible
    if BossW.BossContainer and BossW.BossContainer._dragOverlay
       and BossW.BossContainer._dragOverlay:IsShown()
       and BossW._updateOverlayBounds then
        BossW._updateOverlayBounds(BossW.BossContainer._dragOverlay, BossW.BossContainer)
    end
end
BossW.ApplyLayout = ApplyLayout

local function RefreshAll()
    if not BossW.BossContainer then return end
    ApplyLayout()
    if BossW.ApplyFonts then BossW:ApplyFonts() end
    for i = 1, MAX_BOSS do
        local f = BossW.BossFrames[i]
        if f then
            UpdateFrame(f)
            if f.applyClickActions then f.applyClickActions() end
        end
    end
end
BossW.RefreshAll = RefreshAll

-- ============================================================
-- FRAME CREATION
-- ============================================================
local function CreateBossFrame(index)
    local name = "BossWatchFrame" .. index
    local unit = "boss" .. index

    local f = CreateFrame("Button", name, BossW.BossContainer, "SecureUnitButtonTemplate")
    f:SetAttribute("unit", unit)
    f:SetAttribute("*type1", "target")
    f:SetAttribute("*type2", "togglemenu")
    f:RegisterForClicks("AnyDown")
    f.unit = unit
    f.index = index

    -- Modifier+click actions: secure attributes set out of combat. ApplyClickActions
    -- below is also called from RefreshAll so toggling the option re-applies (gated
    -- on InCombatLockdown, queued via _pendingLayout if needed).
    f.applyClickActions = function()
        if InCombatLockdown() then return false end
        local db = BossW:GetDB()
        if db.clickActions ~= false then
            f:SetAttribute("shift-type1", "macro")
            f:SetAttribute("shift-macrotext1",
                ("/run local i=GetRaidTargetIndex('%s') or 0; if i>=8 then i=0 end; SetRaidTarget('%s', i+1)"):format(unit, unit))
            f:SetAttribute("ctrl-type1", "focus")
        else
            f:SetAttribute("shift-type1", nil)
            f:SetAttribute("shift-macrotext1", nil)
            f:SetAttribute("ctrl-type1", nil)
        end
        return true
    end
    f.applyClickActions()

    RegisterStateDriver(f, "visibility", "[@" .. unit .. ",exists]show;hide")

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetColorTexture(0, 0, 0, 0.6)
    f.bg = bg

    -- Health bar
    local hp = CreateFrame("StatusBar", nil, f)
    hp:SetMinMaxValues(0, 100); hp:SetValue(100)
    f.healthBar = hp
    local hpBg = hp:CreateTexture(nil, "BACKGROUND")
    hpBg:SetAllPoints(hp)
    hpBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    hp.bg = hpBg

    -- Absorb shield overlay (TankWatch pattern).
    -- A StatusBar parented to hp, SetAllPoints, SetReverseFill(true) so its
    -- fill grows from the RIGHT edge leftward. SetMinMaxValues(0, hpMax)
    -- + SetValue(absorbAmount) gives a fill of (absorb/hpMax) of width, on
    -- the right side. Frame level above hp.fill so the absorb is visible
    -- where hp.fill doesn't reach.
    local abs = CreateFrame("StatusBar", nil, hp)
    abs:SetAllPoints(hp)
    abs:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill")
    abs:SetMinMaxValues(0, 1)
    abs:SetValue(0)
    abs:SetReverseFill(true)
    abs:SetFrameLevel(hp:GetFrameLevel() + 4)
    abs:Hide()
    f.absorbBar = abs

    -- Power bar
    local pw = CreateFrame("StatusBar", nil, f)
    pw:SetMinMaxValues(0, 100); pw:SetValue(0)
    f.powerBar = pw
    local pwBg = pw:CreateTexture(nil, "BACKGROUND")
    pwBg:SetAllPoints(pw)
    pwBg:SetColorTexture(0, 0, 0, 0.7)
    pw.bg = pwBg

    -- Portrait (2D)
    local portrait = f:CreateTexture(nil, "ARTWORK")
    portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    portrait:Hide()
    f.portrait = portrait

    local pb = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    pb:SetColorTexture(0, 0, 0, 0.9)
    f.portraitBorder = pb

    -- Power text
    local pwText = pw:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pwText:SetTextColor(1, 1, 1)
    pwText:SetPoint("RIGHT", pw, "RIGHT", -2, 0)
    f.powerText = pwText

    -- Name + health text
    local nameText = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", hp, "LEFT", 4, 0)
    nameText:SetTextColor(1, 1, 1)
    f.nameText = nameText

    local hpText = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hpText:SetPoint("RIGHT", hp, "RIGHT", -4, 0)
    hpText:SetTextColor(1, 1, 1)
    f.healthText = hpText

    local highlight = f:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(f)
    highlight:SetColorTexture(1, 1, 1, 0.1)

    -- Raid target icon (parented to healthBar to draw above the bar)
    local rti = hp:CreateTexture(nil, "OVERLAY", nil, 7)
    rti:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    rti:SetSize(28, 28)
    rti:SetPoint("CENTER", f, "CENTER", 0, 0)
    rti:Hide()
    f.raidTargetIcon = rti

    -- Target highlight border (shown when player.target == this boss)
    local hl = CreateFrame("Frame", nil, f, "BackdropTemplate")
    hl:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
    hl:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -2)
    hl:SetFrameLevel((f:GetFrameLevel() or 1) + 5)
    hl:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    hl:SetBackdropBorderColor(1, 0.82, 0, 1)
    hl:Hide()
    f.targetHighlight = hl

    local ag = hl:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local a1 = ag:CreateAnimation("Alpha")
    a1:SetFromAlpha(1)
    a1:SetToAlpha(0.35)
    a1:SetDuration(0.7)
    a1:SetSmoothing("IN_OUT")
    hl._anim = ag

    -- Events
    f:RegisterEvent("UNIT_HEALTH")
    f:RegisterEvent("UNIT_MAXHEALTH")
    f:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
    f:RegisterEvent("UNIT_POWER_UPDATE")
    f:RegisterEvent("UNIT_MAXPOWER")
    f:RegisterEvent("UNIT_DISPLAYPOWER")
    f:RegisterEvent("UNIT_NAME_UPDATE")
    f:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    f:RegisterEvent("UNIT_TARGETABLE_CHANGED")
    f:RegisterEvent("RAID_TARGET_UPDATE")
    f:RegisterUnitEvent("UNIT_HEALTH", unit)
    f:SetScript("OnEvent", function(self, event, eUnit)
        if event == "RAID_TARGET_UPDATE" then BossW.UpdateRaidTargetIcon(self); return end
        if event == "UNIT_TARGETABLE_CHANGED" and eUnit == unit then UpdateFrame(self); return end
        if eUnit ~= unit then return end
        UpdateFrame(self)
    end)

    return f
end

-- ============================================================
-- INIT
-- ============================================================
function BossW:EnsureCreated()
    if BossW.BossContainer then return end
    local db = BossW:GetDB()
    if not db.enabled then return end

    local container = CreateFrame("Frame", "BossWatchContainer", UIParent)
    container:SetSize(db.frameWidth, (db.frameHeight + db.frameSpacing) * MAX_BOSS)
    container:SetPoint(db.anchor or "RIGHT", UIParent, db.anchor or "RIGHT", db.anchorX or 0, db.anchorY or 0)
    container:SetFrameStrata(db.frameStrata or "MEDIUM")
    container:SetMovable(true)
    container:SetClampedToScreen(true)
    BossW.BossContainer = container

    for i = 1, MAX_BOSS do BossW.BossFrames[i] = CreateBossFrame(i) end
    ApplyLayout()
    if db.hideBlizzard then BossW:HideBlizzardBossFrames() end
end

-- ============================================================
-- MOVER
-- ============================================================
-- Anchors the frame-level bg statically based on db.frameBgWrapsCast.
-- When false, the bg stops above the cast zone so an idle cast bar shows
-- through transparent — when true, bg covers the whole frame.
function BossW._updateFrameBg(frame)
    if not frame or not frame.bg or not frame.powerBar or not frame.healthBar then return end
    local db = BossW:GetDB()
    frame.bg:ClearAllPoints()
    frame.bg:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    frame.bg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    if db.frameBgWrapsCast or db.castBarDetached or not db.showCastBar then
        -- Wraps everything (or there's no inline cast bar to skip)
        frame.bg:SetPoint("BOTTOMLEFT",  frame, "BOTTOMLEFT",  0, 0)
        frame.bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    else
        -- Stops above the cast zone — anchor to the bottom of the band that
        -- covers HP + (optional) Power, which equals the bottom of power
        -- bar if shown, else the bottom of the HP bar.
        local bottomRef = (db.showPowerBar and frame.powerBar) or frame.healthBar
        frame.bg:SetPoint("BOTTOMLEFT",  bottomRef, "BOTTOMLEFT",  0, 0)
        frame.bg:SetPoint("BOTTOMRIGHT", bottomRef, "BOTTOMRIGHT", 0, 0)
    end
end

local function updateOverlayBounds(o, c)
    local db = BossW:GetDB()
    local pSize = (db.portraitPosition and db.portraitPosition ~= "HIDDEN") and (db.portraitSize or 0) or 0
    local leftOff  = (db.portraitPosition == "LEFT")  and (pSize + 2) or 0
    local rightOff = (db.portraitPosition == "RIGHT") and (pSize + 2) or 0
    o:ClearAllPoints()
    o:SetPoint("TOPLEFT",     c, "TOPLEFT",     -leftOff, 0)
    o:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", rightOff, 0)
end
BossW._updateOverlayBounds = updateOverlayBounds

local function ensureDragOverlay()
    local c = BossW.BossContainer
    if c._dragOverlay then return c._dragOverlay end
    local o = CreateFrame("Button", nil, c)
    o:SetFrameStrata("DIALOG")
    updateOverlayBounds(o, c)
    o:EnableMouse(true)
    o:RegisterForDrag("LeftButton")
    o:RegisterForClicks("RightButtonUp")
    local tex = o:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(o)
    tex:SetColorTexture(0, 1, 0, 0.18)
    local label = o:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("CENTER", o, "CENTER", 0, 0)
    label:SetText("BossWatch — left-drag to move, right-click to lock")
    label:SetTextColor(1, 1, 1)
    o:SetScript("OnDragStart", function() c:StartMoving() end)
    o:SetScript("OnDragStop", function()
        c:StopMovingOrSizing()
        local db = BossW:GetDB()
        local point, _, _, x, y = c:GetPoint()
        db.anchor = point
        db.anchorX = x
        db.anchorY = y
        c:ClearAllPoints()
        c:SetPoint(point, UIParent, point, x, y)
    end)
    o:SetScript("OnClick", function(self, btn)
        if btn == "RightButton" then BossW:ToggleMover() end
    end)
    o:Hide()
    c._dragOverlay = o
    return o
end

function BossW:ToggleMover()
    BossW:EnsureCreated()
    local c = BossW.BossContainer
    if not c then return end
    local anyVisible = false
    for i = 1, MAX_BOSS do
        if BossW.BossFrames[i] and BossW.BossFrames[i]:IsShown() then anyVisible = true; break end
    end
    local overlay = ensureDragOverlay()
    if c._movingEnabled then
        overlay:Hide()
        c._movingEnabled = false
        if c._autoTest then c._autoTest = false; BossW:SetTestMode(0) end
        print("|cffeda55fBossWatch:|r mover locked")
    else
        c:SetMovable(true)
        updateOverlayBounds(overlay, c)
        overlay:Show()
        c._movingEnabled = true
        if not anyVisible then
            BossW:SetTestMode(3)
            c._autoTest = true
        end
        print("|cffeda55fBossWatch:|r mover unlocked — left-drag to move, right-click to lock")
    end
end

-- ============================================================
-- TEST MODE
-- ============================================================
local testTicker = CreateFrame("Frame")
testTicker:Hide()
local _testNextCast = {}
local _testElapsed = 0
local _testNextTargetSwap = 0
testTicker:SetScript("OnUpdate", function(self, e)
    _testElapsed = _testElapsed + e
    if _testElapsed < 0.1 then return end
    _testElapsed = 0
    local now = GetTime()
    local active
    local activeIndices = {}
    for i = 1, MAX_BOSS do
        local f = BossW.BossFrames[i]
        if f and f._testMode then
            active = true
            activeIndices[#activeIndices + 1] = i
            f._testHpDir = f._testHpDir or -1
            f._testHp = (f._testHp or 80) + f._testHpDir * (0.3 + i * 0.1)
            if f._testHp <= 10 then f._testHpDir = 1
            elseif f._testHp >= 100 then f._testHpDir = -1 end
            f._testPower = ((f._testPower or 50) + (math.random() * 4 - 2)) % 100
            -- Absorb fluctuates between ~5 and ~45 to make the shield visibly move
            f._testAbsorbDir = f._testAbsorbDir or 1
            f._testAbsorb = (f._testAbsorb or 25) + f._testAbsorbDir * (0.4 + i * 0.15)
            if f._testAbsorb <= 5 then f._testAbsorbDir = 1
            elseif f._testAbsorb >= 45 then f._testAbsorbDir = -1 end
            if not _testNextCast[i] or now >= _testNextCast[i] then
                if BossW.SimulateCast then BossW.SimulateCast(f, math.random() < 0.25) end
                _testNextCast[i] = now + 3 + math.random() * 4
            end
            UpdateFrame(f)
        end
    end
    -- Rotate the fake target every 3s so the user can preview the highlight
    if active and now >= _testNextTargetSwap then
        local pick = activeIndices[math.random(1, #activeIndices)]
        for i = 1, MAX_BOSS do
            local f = BossW.BossFrames[i]
            if f then f._fakeTarget = (i == pick) end
        end
        if BossW._applyTargetHighlight then
            for i = 1, MAX_BOSS do
                local f = BossW.BossFrames[i]
                if f then BossW._applyTargetHighlight(f) end
            end
        end
        _testNextTargetSwap = now + 3
    end
    if not active then self:Hide() end
end)

local _lastTestCount
function BossW:SetTestMode(count)
    BossW:EnsureCreated()
    count = tonumber(count) or 0
    if count < 0 then count = 0 end
    if count > MAX_BOSS then count = MAX_BOSS end
    if count == _lastTestCount then return end
    _lastTestCount = count

    local testNames = { "The Lich King", "Kel'Thuzad", "Onyxia", "Ragnaros", "Illidan Stormrage" }
    local testHp = { 95, 72, 48, 30, 12 }

    for i = 1, MAX_BOSS do
        local f = BossW.BossFrames[i]
        if f then
            if i <= count then
                f._testMode = true
                f._testName = testNames[i]
                f._testHp = testHp[i]
                f._testHpDir = -1
                f._testPower = 50
                f._testAbsorb = 18 + (i * 4)
                if not InCombatLockdown() then
                    RegisterStateDriver(f, "visibility", "show")
                end
                UpdateFrame(f)
            else
                f._testMode = false
                f._testName = nil; f._testHp = nil; f._testHpDir = nil; f._testPower = nil; f._testAbsorb = nil
                f._testAuras = nil
                f._fakeTarget = nil
                _testNextCast[i] = nil
                if f.castBar then f.castBar:Hide() end
                if not InCombatLockdown() then
                    RegisterStateDriver(f, "visibility", "[@" .. f.unit .. ",exists]show;hide")
                end
            end
        end
    end

    -- Trigger ApplyLayout so absorbBar width / textures are refreshed.
    BossW:RefreshAll()

    if count > 0 then
        testTicker:Show()
        print(format("|cffeda55fBossWatch:|r test mode — %d boss%s", count, count == 1 and "" or "es"))
    else
        testTicker:Hide()
        print("|cffeda55fBossWatch:|r test mode off")
    end
end

-- ============================================================
-- EVENTS
-- ============================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_TARGET_CHANGED" then
        for i = 1, BossW.MAX_BOSS do
            local f = BossW.BossFrames[i]
            if f then applyTargetHighlight(f) end
        end
        return
    end
    if event == "PLAYER_REGEN_ENABLED" and _pendingLayout then
        _pendingLayout = false
        BossW:EnsureCreated()
        RefreshAll()
        return
    end
    BossW:EnsureCreated()
    RefreshAll()
end)
