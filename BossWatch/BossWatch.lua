local addonName, BW = ...

-- Expose the addon table globally for /dump and external access.
_G[addonName] = BW

BW.MAX_BOSS = 5
BW.BossFrames = {}
BW.BossContainer = nil

-- ============================================================
-- DEFAULTS
-- ============================================================
BW.Defaults = {
    enabled = true,
    hideBlizzard = true,

    -- Container
    anchor = "RIGHT", anchorX = -50, anchorY = 100,
    frameWidth = 220, frameHeight = 50, frameSpacing = 8, frameScale = 1.0,
    growDirection = "DOWN",
    frameStrata = "MEDIUM",

    -- Portrait (2D Blizzard-style)
    portraitPosition = "RIGHT", portraitSize = 44,

    -- Health
    healthTexture = "Blizzard Raid Bar",
    healthBackgroundAlpha = 0.35,
    healthColorMode = "REACTION", -- REACTION | CLASS_FALLBACK | STATIC
    healthStaticColor = {r = 0.8, g = 0.1, b = 0.1, a = 1},

    -- Power
    showPowerBar = false, powerBarHeight = 6, powerBackgroundAlpha = 0.7,
    powerTexture = "Blizzard Raid Bar",

    -- Cast
    castTexture = "Blizzard Modern",
    showCastBar = true, castBarHeight = 14, castBarDetached = false,
    castBarIconPosition = "LEFT", castBackgroundAlpha = 0.7,
    castBarDetachedAnchor = "BOTTOM", castBarDetachedX = 0, castBarDetachedY = -4,
    castBarDetachedWidth = 0,

    -- Name text
    showName = true, nameAnchor = "RIGHT", nameX = 1, nameY = 0, nameMaxLength = 16,

    -- Health text
    showHealthText = true, healthTextAnchor = "LEFT", healthTextX = 0, healthTextY = 0,
    healthTextFormat = "PERCENT",

    -- Font (applies to all text elements)
    fontFace = "Friz Quadrata TT", fontSize = 12, fontOutline = "NONE",

    -- Power text
    showPowerText = true, powerTextAnchor = "RIGHT", powerTextX = -2, powerTextY = 0,
    powerTextFormat = "PERCENT",

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
}

-- ============================================================
-- DB ACCESS
-- ============================================================

local function seedDefaults(target)
    for k, v in pairs(BW.Defaults) do
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

function BW:GetDB()
    BossWatchDB = BossWatchDB or {}
    -- Migrate legacy broken default (pointed to a Media file that never shipped)
    if BossWatchDB.healthTexture == "Interface\\AddOns\\BossWatch\\Media\\bar.tga" then
        BossWatchDB.healthTexture = "Blizzard Raid Bar"
    end
    -- Migrate previous default ("Blizzard" classic) → modern "Blizzard Raid Bar"
    if BossWatchDB.healthTexture == "Blizzard" then BossWatchDB.healthTexture = "Blizzard Raid Bar" end
    if BossWatchDB.powerTexture  == "Blizzard" then BossWatchDB.powerTexture  = "Blizzard Raid Bar" end
    if BossWatchDB.castTexture   == "Blizzard" then BossWatchDB.castTexture   = "Blizzard Modern" end
    -- Switch the previous cast default to the new modern one
    if BossWatchDB.castTexture   == "Blizzard Raid Bar" then BossWatchDB.castTexture = "Blizzard Modern" end
    seedDefaults(BossWatchDB)
    return BossWatchDB
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

function BW:ResolveTexture(name)
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

function BW:ResolveFont(name)
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

function BW:ApplyFonts()
    if not BW.BossFrames then return end
    local db = BW:GetDB()
    local file = BW:ResolveFont(db.fontFace)
    local size = db.fontSize or 12
    local outline = db.fontOutline or "NONE"
    if outline == "NONE" then outline = "" end

    local function setF(fs, sz, ol)
        if fs then pcall(fs.SetFont, fs, file, sz, ol) end
    end

    for i = 1, BW.MAX_BOSS do
        local f = BW.BossFrames[i]
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
BW.L = setmetatable({}, { __index = function(t, k) return k end })

-- ============================================================
-- HIDE BLIZZARD BOSS FRAMES
-- ============================================================
local blizzardHidden = false
function BW:HideBlizzardBossFrames()
    if blizzardHidden then return end
    blizzardHidden = true
    local container = _G["BossTargetFrameContainer"] or _G["BossFrameContainer"]
    if container then
        container:UnregisterAllEvents()
        container:Hide()
        container.Show = function() end
    end
    for i = 1, BW.MAX_BOSS do
        for _, n in ipairs({ "Boss" .. i .. "TargetFrame", "BossTargetFrame" .. i }) do
            local f = _G[n]
            if f then
                f:UnregisterAllEvents()
                f:Hide()
                f.Show = function() end
            end
        end
    end
end

-- ============================================================
-- SLASH COMMAND
-- ============================================================
SLASH_BOSSWATCH1 = "/bw"
SlashCmdList["BOSSWATCH"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" or msg == "config" or msg == "options" then
        if BW.ToggleOptions then BW:ToggleOptions() end
        return
    end
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    if cmd == "test" then
        if BW.SetTestMode then BW:SetTestMode(tonumber(arg) or 5) end
    elseif cmd == "mover" then
        if BW.ToggleMover then BW:ToggleMover() end
    elseif cmd == "reset" then
        BossWatchDB = nil
        ReloadUI()
    else
        local L = BW.L
        print("|cffeda55fBossWatch:|r " .. L["commands:"])
        print("  /bw            - " .. L["open options"])
        print("  /bw mover      - " .. L["toggle mover"])
        print("  /bw test N     - " .. L["simulate N bosses (0-5)"])
        print("  /bw reset      - " .. L["reset all settings + reload"])
    end
end

-- ============================================================
-- INIT
-- ============================================================
local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function()
    BW:GetDB()
    if BW.EnsureCreated then BW:EnsureCreated() end
    if BW.ApplyFonts then BW:ApplyFonts() end
    if BW.RegisterBlizzardSettings then BW:RegisterBlizzardSettings() end
    print(format(BW.L["|cffeda55fBossWatch|r v%s loaded — type |cffffff00/bw|r for options"],
        C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"))
end)
