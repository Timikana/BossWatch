local addonName, BossW = ...
local L = BossW.L
local O = BossW.Options

local addTooltip   = O.addTooltip
local makeSection  = O.makeSection
local makeCheck    = O.makeCheck
local makeDropdown = O.makeDropdown
local makeSlider   = O.makeSlider

local CreateFrame = CreateFrame
local _G          = _G

function O.Pages.sod(page)
    local y = -8

    -- This page is registered on every TOC for parity, but only loaded on
    -- clients where SodSlotProvider is active (Vanilla, TBC Anniversary).
    -- The tab itself is gated in Panel.lua — this guard is the second
    -- line of defence.
    if not BossW._sodMode then
        local note = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        note:SetPoint("TOPLEFT", 14, y)
        note:SetWidth(680); note:SetJustifyH("LEFT")
        note:SetText(L["This tab only applies to Classic Era / Season of Discovery."])
        return
    end

    -- ============ DETECTION ============
    makeSection(page, L["Detection"], 14, y, "sod.detection"); y = y - 24

    local intro = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", 14, y)
    intro:SetWidth(680); intro:SetJustifyH("LEFT")
    intro:SetText(L["On Classic Era / SoD, boss1..5 unit IDs don't exist. BossWatch fills the frames by scanning your target, your mouseover and visible enemy nameplates. Enable enemy nameplates (Ctrl-V) for auto-detection to work."])
    y = y - 36

    addTooltip(makeCheck(page, L["Include world bosses"], "sodIncludeWorldBosses", 14, y),
        L["Track NPCs classified by the game as 'worldboss' (large open-world bosses)."])
    addTooltip(makeCheck(page, L["Include rare elites"], "sodIncludeRareElites", 260, y),
        L["Track NPCs classified as 'rareelite' (silver dragon + elite border)."])
    y = y - 26

    addTooltip(makeCheck(page, L["Include elites"], "sodIncludeElites", 14, y),
        L["Track NPCs classified as 'elite' (the standard elite gold border). Most raid/dungeon bosses qualify here."])
    addTooltip(makeCheck(page, L["Include rares (non-elite)"], "sodIncludeRares", 260, y),
        L["Track NPCs classified as 'rare' (silver dragon, no elite border). OFF by default — adds noise from regular open-world rares."])
    y = y - 32

    -- ============ CAPACITY ============
    makeSection(page, L["Capacity"], 14, y, "sod.capacity"); y = y - 24

    addTooltip(makeDropdown(page, L["Max simultaneous frames"], "maxBossSoD",
        { { value = 3, text = "3" }, { value = 5, text = "5" }, { value = 8, text = "8" } },
        14, y),
        L["How many elite NPCs can be displayed at once. Changing this requires a /reload."])
    addTooltip(makeSlider(page, L["Release delay (seconds)"], "sodReleaseDelay", 2, 30, 1, 260, y),
        L["After a tracked unit's nameplate goes missing AND combat ends, BossWatch frees its slot after this many seconds."])
    y = y - 64

    -- ============ ACTIONS ============
    makeSection(page, L["Actions"], 14, y, "sod.actions"); y = y - 28

    local btnReset = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnReset:SetSize(200, 22); btnReset:SetPoint("TOPLEFT", 14, y)
    btnReset:SetText(L["Clear all detected slots"])
    btnReset:SetScript("OnClick", function()
        -- Best-effort: trigger PLAYER_ENTERING_WORLD-equivalent flush by
        -- iterating frames and clearing their unit attribute. The next
        -- nameplate event will refill slots from scratch.
        for i = 1, BossW.MAX_BOSS do
            local f = BossW.BossFrames and BossW.BossFrames[i]
            if f and not InCombatLockdown() then
                f:SetAttribute("unit", "none")
            end
        end
        print("|cffeda55fBossWatch:|r " .. L["Slots cleared — they will refill from current target / nameplates."])
    end)
    addTooltip(btnReset, L["Frees every slot manually. Useful if a slot is stuck on a despawned mob."])
end
