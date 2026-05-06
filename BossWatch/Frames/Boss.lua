local addonName, BW = ...

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

local MAX_BOSS = BW.MAX_BOSS

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

local function SetHealthValue(frame, unit)
    local pct = GetSafeHealthPercent(unit)
    pcall(frame.healthBar.SetMinMaxValues, frame.healthBar, 0, 100)
    pcall(frame.healthBar.SetValue, frame.healthBar, pct or 0)
    frame._hpPct = pct or 0
end

local function SetPowerValue(frame, unit)
    if not frame.powerBar or not frame.powerBar:IsShown() then return end
    local okP, p = pcall(UnitPower, unit)
    local okM, pMax = pcall(UnitPowerMax, unit)
    if not okP or not okM then return end
    local okCmp, hasPower = pcall(function() return pMax and pMax > 0 end)
    if not okCmp or not hasPower then
        frame.powerBar:Hide()
        if frame.powerText then frame.powerText:SetText("") end
        return
    end
    frame.powerBar:Show()
    pcall(frame.powerBar.SetMinMaxValues, frame.powerBar, 0, pMax)
    pcall(frame.powerBar.SetValue, frame.powerBar, p)
    frame.powerBar:SetStatusBarColor(GetPowerColor(unit))

    if not frame.powerText then return end
    local db = BW:GetDB()
    if not db.showPowerText then frame.powerText:SetText(""); return end

    local function visualPct()
        local tex = frame.powerBar:GetStatusBarTexture()
        local barW = frame.powerBar:GetWidth()
        if not tex or not barW or barW <= 0 then return 0 end
        return (tex:GetWidth() or 0) / barW * 100
    end

    local fmt = db.powerTextFormat or "PERCENT"
    if fmt == "PERCENT" then
        frame.powerText:SetFormattedText("%d%%", visualPct())
    elseif fmt == "CURRENT" then
        pcall(frame.powerText.SetText, frame.powerText, AbbreviateLargeNumbers(p))
    elseif fmt == "CURRENT_PERCENT" then
        local okAbbr, pStr = pcall(AbbreviateLargeNumbers, p)
        if okAbbr then frame.powerText:SetFormattedText("%s (%d%%)", pStr, visualPct())
        else frame.powerText:SetFormattedText("%d%%", visualPct()) end
    else
        pcall(frame.powerText.SetFormattedText, frame.powerText,
            "%s / %s", AbbreviateLargeNumbers(p), AbbreviateLargeNumbers(pMax))
    end
end

local function FormatHealthText(frame, db, unit)
    if not frame.healthText then return end
    if not db.showHealthText then frame.healthText:SetText(""); return end
    local fmt = db.healthTextFormat or "PERCENT"
    local pct = frame._hpPct or 0
    if fmt == "PERCENT" then
        pcall(frame.healthText.SetFormattedText, frame.healthText, "%d%%", pct)
    elseif fmt == "CURRENT" then
        if frame._testMode then
            frame.healthText:SetText(AbbreviateLargeNumbers((frame._testHp or 0) * 1e6))
        else
            local ok, hp = pcall(UnitHealth, unit)
            if ok and type(hp) == "number" then
                frame.healthText:SetText(AbbreviateLargeNumbers(hp))
            else frame.healthText:SetText("") end
        end
    elseif fmt == "CURRENT_PERCENT" then
        if frame._testMode then
            local hp = (frame._testHp or 0) * 1e6
            frame.healthText:SetFormattedText("%s (%d%%)", AbbreviateLargeNumbers(hp), pct)
        else
            local ok, hp = pcall(UnitHealth, unit)
            if ok and type(hp) == "number" then
                pcall(frame.healthText.SetFormattedText, frame.healthText, "%s (%d%%)", AbbreviateLargeNumbers(hp), pct)
            end
        end
    else
        if frame._testMode then
            frame.healthText:SetFormattedText("%s / %s",
                AbbreviateLargeNumbers((frame._testHp or 0) * 1e6),
                AbbreviateLargeNumbers(1e8))
        else
            local ok1, hp = pcall(UnitHealth, unit)
            local ok2, hpMax = pcall(UnitHealthMax, unit)
            if ok1 and ok2 and type(hp) == "number" and type(hpMax) == "number" then
                frame.healthText:SetFormattedText("%s / %s",
                    AbbreviateLargeNumbers(hp), AbbreviateLargeNumbers(hpMax))
            else frame.healthText:SetText("") end
        end
    end
end

-- ============================================================
-- FRAME UPDATE
-- ============================================================
local function UpdateFrame(frame)
    local unit = frame.unit
    local db = BW:GetDB()

    -- Visibility driven by RegisterStateDriver — don't Show/Hide here.

    -- Name
    if frame.nameText then
        if db.showName then
            local ok, n = pcall(UnitName, unit)
            if not ok or not n then n = frame._testName or ("Boss " .. frame.index) end
            local maxLen = db.nameMaxLength or 0
            if maxLen > 0 then
                pcall(function()
                    if #n > maxLen then n = n:sub(1, maxLen - 1) .. "…" end
                end)
            end
            pcall(frame.nameText.SetText, frame.nameText, n)
        else
            frame.nameText:SetText("")
        end
    end

    -- Portrait (2D)
    if frame.portrait then
        if db.portraitPosition ~= "HIDDEN" then
            frame.portrait:Show()
            SetPortraitTexture(frame.portrait, frame._testMode and "player" or unit)
        else
            frame.portrait:Hide()
        end
    end

    -- Health
    if frame._testMode then
        pcall(frame.healthBar.SetMinMaxValues, frame.healthBar, 0, 100)
        pcall(frame.healthBar.SetValue, frame.healthBar, frame._testHp or 80)
        frame._hpPct = frame._testHp or 80
    else
        SetHealthValue(frame, unit)
    end
    frame.healthBar:SetStatusBarColor(GetHealthColor(db, unit))

    -- Power
    if db.showPowerBar and frame.powerBar then
        frame.powerBar:Show()
        if frame._testMode then
            local p = frame._testPower or 50
            pcall(frame.powerBar.SetMinMaxValues, frame.powerBar, 0, 100)
            pcall(frame.powerBar.SetValue, frame.powerBar, p)
            frame.powerBar:SetStatusBarColor(0.3, 0.4, 0.9)
            if frame.powerText then
                if db.showPowerText then
                    frame.powerText:SetFormattedText("%d%%", p + 0.5)
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
    if db.showRaidTargetIcon and BW.UpdateRaidTargetIcon then
        BW.UpdateRaidTargetIcon(frame)
    elseif frame.raidTargetIcon then
        frame.raidTargetIcon:Hide()
    end

    -- Auras
    if BW.UpdateAuras then BW.UpdateAuras(frame) end
end
BW.UpdateFrame = UpdateFrame

-- ============================================================
-- RAID TARGET ICON
-- ============================================================
function BW.UpdateRaidTargetIcon(frame)
    if not frame.raidTargetIcon then return end
    local unit = frame.unit
    local idx
    if frame._testMode then
        idx = frame.index
    else
        local ok, v = pcall(GetRaidTargetIndex, unit)
        if ok then idx = v end
    end
    if not idx then frame.raidTargetIcon:Hide(); return end
    local applied
    local ok = pcall(function()
        if SetRaidTargetIconTexCoord then
            SetRaidTargetIconTexCoord(frame.raidTargetIcon, idx)
        elseif SetRaidTargetIconTexture then
            SetRaidTargetIconTexture(frame.raidTargetIcon, idx)
        end
        applied = true
    end)
    local okZero, isZero = pcall(function() return idx == 0 end)
    if ok and applied and not (okZero and isZero) then
        frame.raidTargetIcon:Show()
    else
        frame.raidTargetIcon:Hide()
    end
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
    local db = BW:GetDB()
    local container = BW.BossContainer
    if not container then return end

    if InCombatLockdown() then _pendingLayout = true; return end

    container:SetScale(db.frameScale or 1)
    container:SetFrameStrata(db.frameStrata or "MEDIUM")

    local anchor = db.anchor or "RIGHT"
    container:ClearAllPoints()
    container:SetPoint(anchor, UIParent, anchor, db.anchorX or 0, db.anchorY or 0)

    local hpTex = BW:ResolveTexture(db.healthTexture)
    local pwTex = BW:ResolveTexture(db.powerTexture or db.healthTexture)

    for i = 1, MAX_BOSS do
        local f = BW.BossFrames[i]
        if not f then break end

        f:SetSize(db.frameWidth, db.frameHeight)
        f:ClearAllPoints()
        if i == 1 then
            f:SetPoint("TOP", container, "TOP", 0, 0)
        else
            local prev = BW.BossFrames[i - 1]
            local s = db.frameSpacing
            if db.growDirection == "UP" then
                f:SetPoint("BOTTOM", prev, "TOP", 0, s)
            else
                f:SetPoint("TOP", prev, "BOTTOM", 0, -s)
            end
        end

        if f.healthBar then
            f.healthBar:SetStatusBarTexture(hpTex)
            if f.healthBar.bg then
                f.healthBar.bg:SetColorTexture(0.1, 0.1, 0.1, db.healthBackgroundAlpha or 0.35)
            end
        end
        if f.powerBar then
            f.powerBar:SetStatusBarTexture(pwTex)
            if f.powerBar.bg then
                f.powerBar.bg:SetColorTexture(0, 0, 0, db.powerBackgroundAlpha or 0.7)
            end
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

        f.healthBar:ClearAllPoints()
        f.healthBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        f.healthBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
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
            local a = db.nameAnchor
            if not VALID_ANCHOR9[a] then a = "LEFT"; db.nameAnchor = a end
            f.nameText:SetPoint(a, f.healthBar, a, db.nameX or 0, db.nameY or 0)
            f.nameText:SetJustifyH(justifyOf(a))
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

        if BW.LayoutCastBar then BW.LayoutCastBar(f, db) end
        if BW.LayoutAuras then BW.LayoutAuras(f, db) end
    end
end
BW.ApplyLayout = ApplyLayout

local function RefreshAll()
    if not BW.BossContainer then return end
    ApplyLayout()
    for i = 1, MAX_BOSS do
        local f = BW.BossFrames[i]
        if f then UpdateFrame(f) end
    end
end
BW.RefreshAll = RefreshAll

-- ============================================================
-- FRAME CREATION
-- ============================================================
local function CreateBossFrame(index)
    local name = "BossWatchFrame" .. index
    local unit = "boss" .. index

    local f = CreateFrame("Button", name, BW.BossContainer, "SecureUnitButtonTemplate")
    f:SetAttribute("unit", unit)
    f:SetAttribute("*type1", "target")
    f:SetAttribute("*type2", "togglemenu")
    f:RegisterForClicks("AnyDown")
    f.unit = unit
    f.index = index

    RegisterStateDriver(f, "visibility", "[@" .. unit .. ",exists]show;hide")

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetColorTexture(0, 0, 0, 0.6)

    -- Health bar
    local hp = CreateFrame("StatusBar", nil, f)
    hp:SetMinMaxValues(0, 100); hp:SetValue(100)
    f.healthBar = hp
    local hpBg = hp:CreateTexture(nil, "BACKGROUND")
    hpBg:SetAllPoints(hp)
    hpBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    hp.bg = hpBg

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

    -- Events
    f:RegisterEvent("UNIT_HEALTH")
    f:RegisterEvent("UNIT_MAXHEALTH")
    f:RegisterEvent("UNIT_POWER_UPDATE")
    f:RegisterEvent("UNIT_MAXPOWER")
    f:RegisterEvent("UNIT_DISPLAYPOWER")
    f:RegisterEvent("UNIT_NAME_UPDATE")
    f:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    f:RegisterEvent("UNIT_TARGETABLE_CHANGED")
    f:RegisterEvent("RAID_TARGET_UPDATE")
    f:RegisterUnitEvent("UNIT_HEALTH", unit)
    f:SetScript("OnEvent", function(self, event, eUnit)
        if event == "RAID_TARGET_UPDATE" then BW.UpdateRaidTargetIcon(self); return end
        if event == "UNIT_TARGETABLE_CHANGED" and eUnit == unit then UpdateFrame(self); return end
        if eUnit ~= unit then return end
        UpdateFrame(self)
    end)

    return f
end

-- ============================================================
-- INIT
-- ============================================================
function BW:EnsureCreated()
    if BW.BossContainer then return end
    local db = BW:GetDB()
    if not db.enabled then return end

    local container = CreateFrame("Frame", "BossWatchContainer", UIParent)
    container:SetSize(db.frameWidth, (db.frameHeight + db.frameSpacing) * MAX_BOSS)
    container:SetPoint(db.anchor or "RIGHT", UIParent, db.anchor or "RIGHT", db.anchorX or 0, db.anchorY or 0)
    container:SetFrameStrata(db.frameStrata or "MEDIUM")
    container:SetMovable(true)
    BW.BossContainer = container

    for i = 1, MAX_BOSS do BW.BossFrames[i] = CreateBossFrame(i) end
    ApplyLayout()
    if db.hideBlizzard then BW:HideBlizzardBossFrames() end
end

-- ============================================================
-- MOVER
-- ============================================================
local function ensureDragOverlay()
    local c = BW.BossContainer
    if c._dragOverlay then return c._dragOverlay end
    local o = CreateFrame("Frame", nil, c)
    o:SetFrameStrata("DIALOG")
    o:SetAllPoints(c)
    o:EnableMouse(true)
    o:RegisterForDrag("LeftButton")
    local tex = o:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints(o)
    tex:SetColorTexture(0, 1, 0, 0.18)
    local label = o:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("CENTER", o, "CENTER", 0, 0)
    label:SetText("BossWatch — drag to move")
    label:SetTextColor(1, 1, 1)
    o:SetScript("OnDragStart", function() c:StartMoving() end)
    o:SetScript("OnDragStop", function()
        c:StopMovingOrSizing()
        local db = BW:GetDB()
        local point, _, _, x, y = c:GetPoint()
        db.anchor = point
        db.anchorX = x
        db.anchorY = y
        c:ClearAllPoints()
        c:SetPoint(point, UIParent, point, x, y)
    end)
    o:Hide()
    c._dragOverlay = o
    return o
end

function BW:ToggleMover()
    BW:EnsureCreated()
    local c = BW.BossContainer
    if not c then return end
    local anyVisible = false
    for i = 1, MAX_BOSS do
        if BW.BossFrames[i] and BW.BossFrames[i]:IsShown() then anyVisible = true; break end
    end
    local overlay = ensureDragOverlay()
    if c._movingEnabled then
        overlay:Hide()
        c._movingEnabled = false
        if c._autoTest then c._autoTest = false; BW:SetTestMode(0) end
        print("|cffeda55fBossWatch:|r mover locked")
    else
        c:SetMovable(true)
        overlay:Show()
        c._movingEnabled = true
        if not anyVisible then
            BW:SetTestMode(3)
            c._autoTest = true
        end
        print("|cffeda55fBossWatch:|r mover unlocked — drag the green overlay")
    end
end

-- ============================================================
-- TEST MODE
-- ============================================================
local testTicker = CreateFrame("Frame")
testTicker:Hide()
local _testNextCast = {}
local _testElapsed = 0
testTicker:SetScript("OnUpdate", function(self, e)
    _testElapsed = _testElapsed + e
    if _testElapsed < 0.1 then return end
    _testElapsed = 0
    local now = GetTime()
    local active
    for i = 1, MAX_BOSS do
        local f = BW.BossFrames[i]
        if f and f._testMode then
            active = true
            f._testHpDir = f._testHpDir or -1
            f._testHp = (f._testHp or 80) + f._testHpDir * (0.3 + i * 0.1)
            if f._testHp <= 10 then f._testHpDir = 1
            elseif f._testHp >= 100 then f._testHpDir = -1 end
            f._testPower = ((f._testPower or 50) + (math.random() * 4 - 2)) % 100
            if not _testNextCast[i] or now >= _testNextCast[i] then
                if BW.SimulateCast then BW.SimulateCast(f, math.random() < 0.25) end
                _testNextCast[i] = now + 3 + math.random() * 4
            end
            UpdateFrame(f)
        end
    end
    if not active then self:Hide() end
end)

local _lastTestCount
function BW:SetTestMode(count)
    BW:EnsureCreated()
    count = tonumber(count) or 0
    if count < 0 then count = 0 end
    if count > MAX_BOSS then count = MAX_BOSS end
    if count == _lastTestCount then return end
    _lastTestCount = count

    local testNames = { "Archavon", "Onyxia", "Ragnaros", "Nefarian", "Deathwing" }
    local testHp = { 95, 72, 48, 30, 12 }

    for i = 1, MAX_BOSS do
        local f = BW.BossFrames[i]
        if f then
            if i <= count then
                f._testMode = true
                f._testName = testNames[i]
                f._testHp = testHp[i]
                f._testHpDir = -1
                f._testPower = 50
                if not InCombatLockdown() then
                    RegisterStateDriver(f, "visibility", "show")
                end
                UpdateFrame(f)
            else
                f._testMode = false
                f._testName = nil; f._testHp = nil; f._testHpDir = nil; f._testPower = nil
                f._testAuras = nil
                _testNextCast[i] = nil
                if f.castBar then f.castBar:Hide() end
                if not InCombatLockdown() then
                    RegisterStateDriver(f, "visibility", "[@" .. f.unit .. ",exists]show;hide")
                end
            end
        end
    end

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
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" and _pendingLayout then
        _pendingLayout = false
        BW:EnsureCreated()
        RefreshAll()
        return
    end
    BW:EnsureCreated()
    RefreshAll()
end)
