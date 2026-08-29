local addonName, BossW = ...
local L = BossW.L
local O = BossW.Options

local addTooltip          = O.addTooltip
local makeSlider          = O.makeSlider
local makeCheck           = O.makeCheck
local makeDropdown        = O.makeDropdown
local makeSection         = O.makeSection
local ANCHOR9             = O.ANCHOR9

function O.Pages.auras(page)
    local y = -8

    -- ============ FILTER ============
    makeSection(page, L["Filter"], 14, y, "auras.filter"); y = y - 24
    addTooltip(makeCheck(page, L["Show Auras"], "showAuras", 14, y),
        L["Show buffs or debuffs on the boss frame."])
    addTooltip(makeDropdown(page, L["Filter"], "aurasFilter", {
        { text = L["Debuffs (HARMFUL)"], value = "HARMFUL" },
        { text = L["Buffs (HELPFUL)"],   value = "HELPFUL" },
    }, 184, y), L["Which kind of auras to display: debuffs (HARMFUL) or buffs (HELPFUL)."])
    y = y - 56
    -- On Retail Midnight 12.0, Blizzard secret-tags isFromPlayerOrPlayerPet
    -- and sourceUnit on hostile-unit auras, which made MINE / NOT_MINE
    -- unreliable. On 12.1+ the AuraContainer engine evaluates these filters
    -- SECURE-SIDE against the real data, so they're exact again — only show
    -- the (!) warning when the engine is NOT available (12.0 clients).
    local isRetailMidnight = (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE)
        and not (BossW.AuraEngine and BossW.AuraEngine.IsSupported())
    local labelMine    = L["Only mine"]
    local labelNotMine = L["Hide mine"]
    local sourceTip    = L["Filter by who applied the aura: anyone, only you, hide yours, or only boss-cast."]
    if isRetailMidnight then
        -- ⚠ doesn't render in the WoW dropdown font, use (!) instead.
        labelMine    = labelMine    .. " |cffffaa00(!)|r"
        labelNotMine = labelNotMine .. " |cffffaa00(!)|r"
        sourceTip = sourceTip .. "\n\n|cffffaa00" .. L["⚠ On Retail Midnight 12.0+, Blizzard restricts access to the aura source on hostile units (secret-tagged fields). 'Only mine' / 'Hide mine' may misclassify some boss debuffs — no boss-frame addon has a clean workaround right now."] .. "|r"
    end
    addTooltip(makeDropdown(page, L["Source"], "aurasSource", {
        { text = L["All (Blizzard-like)"], value = "ALL" },
        { text = labelMine,                value = "MINE" },
        { text = labelNotMine,             value = "NOT_MINE" },
        { text = L["Boss-cast only"],      value = "BOSS_ONLY" },
    }, 14, y, 180), sourceTip)

    -- ============ SIZE ============
    y = y - 60
    makeSection(page, L["Size"], 14, y, "auras.size"); y = y - 24
    addTooltip(makeSlider(page, L["Max Count"], "aurasMaxCount", 1, 8, 1, 14, y),
        L["Maximum number of aura icons displayed per frame."])
    addTooltip(makeSlider(page, L["Size"], "aurasSize", 12, 48, 1, 260, y),
        L["Size of each aura icon in pixels."])
    y = y - 56
    addTooltip(makeSlider(page, L["Spacing"], "aurasSpacing", 0, 10, 1, 14, y),
        L["Gap between aura icons in pixels."])

    -- ============ LAYOUT ============
    y = y - 60
    makeSection(page, L["Layout"], 14, y, "auras.layout"); y = y - 24
    addTooltip(makeDropdown(page, L["Anchor"], "aurasAnchor", ANCHOR9(), 14, y),
        L["Where the aura row attaches on the boss frame."])
    addTooltip(makeDropdown(page, L["Grow X"], "aurasGrowX", {
        { text = L["Left"],  value = "LEFT" },
        { text = L["Right"], value = "RIGHT" },
    }, 260, y), L["Direction the icons stack horizontally from the anchor."])
    y = y - 56
    addTooltip(makeSlider(page, L["Offset X"], "aurasX", -200, 200, 1, 14, y),
        L["Horizontal offset of the aura row."])
    addTooltip(makeSlider(page, L["Offset Y"], "aurasY", -200, 200, 1, 260, y),
        L["Vertical offset of the aura row."])

    -- ============ DISPLAY ============
    y = y - 60
    makeSection(page, L["Display"], 14, y, "auras.display"); y = y - 24
    addTooltip(makeCheck(page, L["Show Stacks"], "aurasShowStacks", 14, y),
        L["Display aura stack count when applicable."])
    addTooltip(makeCheck(page, L["Show Timer"],  "aurasShowTimer",  184, y),
        L["Display the remaining duration on the icon."])
    y = y - 30
    addTooltip(makeCheck(page, L["Show Tooltip on Hover"], "aurasTooltip", 14, y),
        L["Show the standard Blizzard tooltip when hovering an aura icon. Some boss debuffs may show partial info due to the secret-value protection of WoW Midnight."])
    y = y - 30
    addTooltip(makeDropdown(page, L["Timer Placement"], "aurasTimerPlacement", {
        { text = L["Inside (centered)"], value = "INSIDE" },
        { text = L["Below icon"],        value = "BELOW" },
        { text = L["Above icon"],        value = "ABOVE" },
    }, 14, y), L["Where the timer text is positioned relative to the icon."])
end
