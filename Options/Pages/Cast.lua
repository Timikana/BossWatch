local addonName, BossW = ...
local L = BossW.L
local O = BossW.Options

local addTooltip          = O.addTooltip
local markAsNew           = O.markAsNew
local makeSlider          = O.makeSlider
local makeCheck           = O.makeCheck
local makeDropdown        = O.makeDropdown
local makeMediaDropdown   = O.makeMediaDropdown
local makeSection         = O.makeSection
local ANCHOR9             = O.ANCHOR9

function O.Pages.cast(page)
    local y = -8

    -- ============ DISPLAY ============
    makeSection(page, L["Display"], 14, y, "cast.display"); y = y - 24
    addTooltip(makeCheck(page, L["Show Cast Bar"], "showCastBar", 14, y),
        L["Show a cast bar under the boss frame when it's casting."])
    addTooltip(makeCheck(page, L["Detached"], "castBarDetached", 184, y),
        L["Detach the cast bar from the boss frame so you can place it anywhere on screen."])
    y = y - 30
    addTooltip(makeMediaDropdown(page, L["Cast Bar Texture"], "castTexture", "statusbar", 14, y, 180, {1, 0.82, 0}),
        L["Status bar texture used for the cast bar fill."])
    y = y - 50
    addTooltip(markAsNew(makeSlider(page, L["Cast bar height"], "castBarHeight", 8, 40, 1, 14, y), "castBarHeight_dim"),
        L["Height of the cast bar in pixels."])
    addTooltip(makeSlider(page, L["Cast bg alpha"], "castBackgroundAlpha", 0, 1, 0.05, 260, y),
        L["Opacity of the cast bar's empty/background portion."])

    -- ============ SPELL ICON ============
    y = y - 60
    makeSection(page, L["Spell Icon"], 14, y, "cast.spellicon"); y = y - 24
    addTooltip(makeDropdown(page, L["Icon Position"], "castBarIconPosition", {
        { text = L["Left"], value = "LEFT" }, { text = L["Right"], value = "RIGHT" },
    }, 14, y), L["Side of the cast bar where the spell icon is shown."])

    -- ============ DETACHED POSITION ============
    y = y - 60
    makeSection(page, L["Detached Position"], 14, y, "cast.detached"); y = y - 24
    addTooltip(makeDropdown(page, L["Detached Anchor"], "castBarDetachedAnchor", ANCHOR9(), 14, y),
        L["Screen anchor used as origin when the cast bar is detached."])
    addTooltip(makeSlider(page, L["Detached Width (0=auto)"], "castBarDetachedWidth", 0, 400, 1, 260, y),
        L["Width of the detached cast bar. 0 keeps the boss frame width."])
    y = y - 56
    addTooltip(makeSlider(page, L["Detached Offset X"], "castBarDetachedX", -200, 200, 1, 14, y),
        L["Horizontal offset from the detached anchor."])
    addTooltip(makeSlider(page, L["Detached Offset Y"], "castBarDetachedY", -200, 200, 1, 260, y),
        L["Vertical offset from the detached anchor."])
end
