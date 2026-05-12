local addonName, BossW = ...
local L = BossW.L
local O = BossW.Options

local addTooltip          = O.addTooltip
local makeSlider          = O.makeSlider
local makeCheck           = O.makeCheck
local makeDropdown        = O.makeDropdown
local makeMediaDropdown   = O.makeMediaDropdown
local makeSection         = O.makeSection
local ANCHOR9             = O.ANCHOR9

function O.Pages.text(page)
    local y = -8

    local FORMATS = {
        { text = L["Percent (50%)"],         value = "PERCENT" },
        { text = L["Raw (Blizzard native)"], value = "RAW" },
        { text = L["Current"],               value = "CURRENT" },
        { text = L["Current + Percent"],     value = "CURRENT_PERCENT" },
    }

    -- ============ NAME ============
    makeSection(page, L["Name"], 14, y, "text.name"); y = y - 24
    addTooltip(makeCheck(page, L["Show Name"], "showName", 14, y),
        L["Show the boss name on the frame."])
    addTooltip(makeDropdown(page, L["Name Position"], "nameAnchor", ANCHOR9(), 184, y),
        L["Anchor point where the name is attached on the frame."])
    y = y - 56
    addTooltip(makeSlider(page, L["Name Offset X"], "nameX", -80, 80, 1, 14, y),
        L["Horizontal offset of the name from its anchor."])
    addTooltip(makeSlider(page, L["Name Offset Y"], "nameY", -80, 80, 1, 260, y),
        L["Vertical offset of the name from its anchor."])
    y = y - 56
    addTooltip(makeSlider(page, L["Name max length (0=off)"], "nameMaxLength", 0, 40, 1, 14, y, 250),
        L["Visually clip the name to roughly this many characters (~7px each). 0 disables. Works on real bosses too — width-based, not string-based."])

    -- ============ HEALTH TEXT ============
    y = y - 60
    makeSection(page, L["Health Text"], 14, y, "text.health"); y = y - 24
    addTooltip(makeCheck(page, L["Show Health Text"], "showHealthText", 14, y),
        L["Display HP value as text on the health bar."])
    addTooltip(makeDropdown(page, L["HP text position"], "healthTextAnchor", ANCHOR9(), 184, y),
        L["Anchor point of the HP text on the bar."])
    y = y - 56
    addTooltip(makeSlider(page, L["HP text Offset X"], "healthTextX", -80, 80, 1, 14, y),
        L["Horizontal offset of the HP text."])
    addTooltip(makeSlider(page, L["HP text Offset Y"], "healthTextY", -80, 80, 1, 260, y),
        L["Vertical offset of the HP text."])
    y = y - 56
    addTooltip(makeDropdown(page, L["HP format"], "healthTextFormat", FORMATS, 14, y, 200),
        L["How the HP value is displayed.\n\n|cffffd200Percent|r — uses UnitHealthPercent, always clean (50%).\n|cffffd200Raw|r — Blizzard native passthrough, may show K-prefixed or raw depending on magnitude.\n|cffffd200Current|r — Blizzard's AbbreviateLargeNumbers (K/M smart abbrev when applicable).\n|cffffd200Current + Percent|r — both combined.\n\nOn hostile boss frames, secret-tagged values limit what can be displayed; Blizzard's render is used as-is."])

    -- ============ POWER TEXT ============
    y = y - 60
    makeSection(page, L["Power Text"], 14, y, "text.power"); y = y - 24
    addTooltip(makeCheck(page, L["Show Power Text"], "showPowerText", 14, y),
        L["Display power value as text on the power bar."])
    -- Power on hostile bosses returns secret-tagged values: arithmetic and
    -- abbreviation are blocked. Only Current (raw) via Blizzard %s passthrough
    -- works reliably across all units. Percent is unreliable on secret-tagged
    -- targets (texture width also secret) so we don't expose it for power.
    local POWER_FORMATS = {
        { text = L["Current (raw)"], value = "CURRENT.RAW" },
    }
    addTooltip(makeDropdown(page, L["Power format"], "powerTextFormat", POWER_FORMATS, 184, y, 200),
        L["Format of the power value. On hostile bosses with secret-tagged values, only Percent and Current (raw) work."])

    -- ============ FONT ============
    y = y - 60
    makeSection(page, L["Font (applies to all text)"], 14, y, "text.font"); y = y - 24
    addTooltip(makeMediaDropdown(page, L["Font"], "fontFace", "font", 14, y, 180),
        L["Font used for every text on the boss frames."])
    y = y - 56
    addTooltip(makeSlider(page, L["Font Size"], "fontSize", 8, 24, 1, 14, y),
        L["Base font size in points."])
    addTooltip(makeDropdown(page, L["Outline"], "fontOutline", {
        { text = L["None"],          value = "NONE" },
        { text = L["Outline"],       value = "OUTLINE" },
        { text = L["Thick Outline"], value = "THICKOUTLINE" },
    }, 260, y), L["Black outline drawn around text for readability."])

end
