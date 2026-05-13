local addonName, BossW = ...
local L = BossW.L
local O = BossW.Options

local addTooltip          = O.addTooltip
local markAsNew           = O.markAsNew
local makeSlider          = O.makeSlider
local makeCheck           = O.makeCheck
local makeDropdown        = O.makeDropdown
local makeMediaDropdown   = O.makeMediaDropdown
local makeColorPicker     = O.makeColorPicker
local makeSection         = O.makeSection

function O.Pages.bars(page)
    local y = -8

    -- ============ HEALTH ============
    makeSection(page, L["Health"], 14, y, "bars.health"); y = y - 24
    addTooltip(makeMediaDropdown(page, L["Health Texture"], "healthTexture", "statusbar", 14, y, 180, {0.9, 0.2, 0.2}),
        L["Status bar texture used for the boss health bar."])
    y = y - 50
    addTooltip(makeDropdown(page, L["Color mode"], "healthColorMode", {
        { text = L["Reaction (Blizzard)"], value = "REACTION" },
        { text = L["Class fallback"],      value = "CLASS_FALLBACK" },
        { text = L["Custom static"],       value = "STATIC" },
    }, 14, y, 180), L["How the health bar is colored: by reaction (red/yellow/green), by class, or one fixed color."])
    addTooltip(makeColorPicker(page, L["Static color"], "healthStaticColor", 280, y),
        L["Fixed color used when the mode above is set to 'Custom static'."])
    y = y - 56
    addTooltip(makeSlider(page, L["HP background alpha"], "healthBackgroundAlpha", 0, 1, 0.05, 14, y),
        L["Opacity of the empty (un-filled) part of the health bar."])
    addTooltip(markAsNew(makeCheck(page, L["Smooth bar animation"], "smoothBars", 260, y), "smoothBars"),
        L["Animate the health bar between values instead of jumping. Disable for instant updates."])

    -- ============ POWER ============
    y = y - 60
    makeSection(page, L["Power"], 14, y, "bars.power"); y = y - 24
    addTooltip(makeCheck(page, L["Show Power Bar"], "showPowerBar", 14, y),
        L["Display the power bar below the health bar."])
    y = y - 30
    addTooltip(makeMediaDropdown(page, L["Power Texture"], "powerTexture", "statusbar", 14, y, 180, {0.3, 0.45, 1}),
        L["Status bar texture used for the boss power (mana / rage / etc.) bar."])
    y = y - 50
    addTooltip(markAsNew(makeSlider(page, L["Power bar height"], "powerBarHeight", 2, 20, 1, 14, y), "powerBarHeight_dim"),
        L["Height of the power bar in pixels (resource: mana, rage, energy, etc.)."])
    addTooltip(makeSlider(page, L["Power background alpha"], "powerBackgroundAlpha", 0, 1, 0.05, 260, y),
        L["Opacity of the empty part of the power bar."])

    -- ============ ABSORBS ============
    y = y - 60
    makeSection(page, L["Absorbs"], 14, y, "bars.absorbs"); y = y - 24
    addTooltip(markAsNew(makeCheck(page, L["Show absorbs / shields"], "showAbsorbs", 14, y), "showAbsorbs"),
        L["Display incoming damage absorbs (shields, bubbles) as a translucent overlay extending the health bar."])
    addTooltip(markAsNew(makeColorPicker(page, L["Absorb color"], "absorbColor", 280, y), "absorbColor"),
        L["Color and opacity of the absorb overlay. Default matches Blizzard's standard shield cyan."])
    y = y - 56
    addTooltip(markAsNew(makeMediaDropdown(page, L["Absorb Texture"], "absorbTexture", "statusbar", 14, y, 180, {0.6, 0.82, 1}), "absorbTexture"),
        L["Status bar texture used for the absorb overlay."])

    -- ============ BACKGROUND ============
    y = y - 60
    makeSection(page, L["Background"], 14, y, "bars.background"); y = y - 24
    addTooltip(markAsNew(makeMediaDropdown(page, L["Background Texture"], "barBackgroundTexture", "statusbar", 14, y, 180), "barBackgroundTexture"),
        L["Texture used behind the bars (the empty / dark portion)."])
    y = y - 50
    addTooltip(markAsNew(makeSlider(page, L["Frame background alpha"], "frameBackgroundAlpha", 0, 1, 0.05, 14, y), "frameBackgroundAlpha"),
        L["Opacity of the dark frame backdrop behind everything."])
    y = y - 56
    addTooltip(markAsNew(makeCheck(page, L["Frame bg wraps cast zone"], "frameBgWrapsCast", 14, y), "frameBgWrapsCast"),
        L["When on, the frame background extends down to include the cast bar area."])

end
