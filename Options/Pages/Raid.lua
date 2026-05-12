local addonName, BossW = ...
local L = BossW.L
local O = BossW.Options

local addTooltip          = O.addTooltip
local makeSlider          = O.makeSlider
local makeCheck           = O.makeCheck
local makeDropdown        = O.makeDropdown
local makeSection         = O.makeSection
local ANCHOR9             = O.ANCHOR9

function O.Pages.raid(page)
    local y = -8

    makeSection(page, L["Raid Target Icon"], 14, y, "raid.icon"); y = y - 24

    local note = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 14, y)
    note:SetWidth(680); note:SetJustifyH("LEFT")
    note:SetText(L["Position the raid target icon (skull, cross, star...) on each boss frame."])
    y = y - 26

    addTooltip(makeCheck(page, L["Show Raid Target Icon"], "showRaidTargetIcon", 14, y),
        L["Display the raid target icon (if any) over each boss frame."])
    y = y - 30
    addTooltip(makeDropdown(page, L["Anchor"], "raidTargetAnchor", ANCHOR9(), 14, y),
        L["Anchor point of the raid icon on the frame."])
    y = y - 56
    addTooltip(makeSlider(page, L["Offset X"], "raidTargetX", -200, 200, 1, 14, y),
        L["Horizontal offset of the raid icon."])
    addTooltip(makeSlider(page, L["Offset Y"], "raidTargetY", -200, 200, 1, 260, y),
        L["Vertical offset of the raid icon."])
    y = y - 56
    addTooltip(makeSlider(page, L["Size"], "raidTargetSize", 10, 64, 1, 14, y),
        L["Size of the raid icon in pixels."])
    addTooltip(makeSlider(page, L["Alpha"], "raidTargetAlpha", 0, 1, 0.05, 260, y),
        L["Opacity of the raid icon."])
end
