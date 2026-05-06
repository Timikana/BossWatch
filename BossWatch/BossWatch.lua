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
    healthTexture = "Interface\\AddOns\\BossWatch\\Media\\bar.tga",
    healthBackgroundAlpha = 0.35,
    healthColorMode = "REACTION", -- REACTION | CLASS_FALLBACK | STATIC
    healthStaticColor = {r = 0.8, g = 0.1, b = 0.1, a = 1},

    -- Power
    showPowerBar = false, powerBarHeight = 6, powerBackgroundAlpha = 0.7,

    -- Cast
    showCastBar = true, castBarHeight = 14, castBarDetached = false,
    castBarIconPosition = "LEFT", castBackgroundAlpha = 0.7,
    castBarDetachedAnchor = "BOTTOM", castBarDetachedX = 0, castBarDetachedY = -4,
    castBarDetachedWidth = 0,

    -- Name text
    showName = true, nameAnchor = "RIGHT", nameX = 1, nameY = 0, nameMaxLength = 16,

    -- Health text
    showHealthText = true, healthTextAnchor = "LEFT", healthTextX = 0, healthTextY = 0,
    healthTextFormat = "PERCENT",

    -- Power text
    showPowerText = true, powerTextAnchor = "RIGHT", powerTextX = -2, powerTextY = 0,
    powerTextFormat = "PERCENT",

    -- Raid target icon
    showRaidTargetIcon = true, raidTargetAnchor = "CENTER",
    raidTargetX = 0, raidTargetY = 0, raidTargetSize = 28, raidTargetAlpha = 0.9,

    -- Auras
    showAuras = true, aurasFilter = "HARMFUL", aurasSource = "ALL",
    aurasMaxCount = 3, aurasSize = 22, aurasSpacing = 2,
    aurasAnchor = "TOPRIGHT", aurasX = 0, aurasY = 0,
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
    seedDefaults(BossWatchDB)
    return BossWatchDB
end

-- ============================================================
-- TEXTURE RESOLUTION (no LSM dep — LSM optional)
-- ============================================================
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
        print("|cffeda55fBossWatch:|r commands:")
        print("  /bw            - open options")
        print("  /bw mover      - toggle mover")
        print("  /bw test N     - simulate N bosses (0-5)")
        print("  /bw reset      - reset all settings + reload")
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
    print(format("|cffeda55fBossWatch|r v%s loaded — type |cffffff00/bw|r for options",
        C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"))
end)
