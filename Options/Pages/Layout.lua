local addonName, BossW = ...
local L = BossW.L
local O = BossW.Options

-- Local aliases so the original body works unchanged.
local addTooltip          = O.addTooltip
local markAsNew           = O.markAsNew
local _registerInSection  = O._registerInSection
local makeSlider          = O.makeSlider
local makeCheck           = O.makeCheck
local makeDropdown        = O.makeDropdown
local makeColorPicker     = O.makeColorPicker
local makeSection         = O.makeSection
local ANCHOR9             = O.ANCHOR9

local CreateFrame = CreateFrame
local format = string.format
local ipairs, tostring = ipairs, tostring

function O.Pages.layout(page)
    local y = -8

    -- ============ ACTIONS ============
    makeSection(page, L["Actions"], 14, y, "layout.actions"); y = y - 22

    local btnMover = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnMover:SetSize(160, 22); btnMover:SetPoint("TOPLEFT", 14, y)
    btnMover:SetText(L["Unlock / Lock Mover"])
    btnMover:SetScript("OnClick", function() BossW:ToggleMover() end)
    addTooltip(btnMover, L["Toggle a draggable handle on the boss frames container so you can move it on screen."])
    _registerInSection(btnMover)

    local label = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", 184, y - 4)
    label:SetText(L["Test:"])
    _registerInSection(label)

    local function currentTestCount()
        local n = 0
        for i = 1, 5 do
            if BossW.BossFrames[i] and BossW.BossFrames[i]._testMode then n = n + 1 end
        end
        return n
    end

    local testBtns = {}
    local function refreshTestBtns()
        local n = currentTestCount()
        for i, b in ipairs(testBtns) do
            if b._count == n then b:LockHighlight() else b:UnlockHighlight() end
        end
    end

    local xs = 220
    for _, count in ipairs({ 0, 1, 2, 3, 4, 5 }) do
        local b = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
        b:SetSize(36, 22)
        b:SetPoint("TOPLEFT", xs, y)
        b:SetText(count == 0 and L["Off"] or tostring(count))
        b._count = count
        b:SetScript("OnClick", function() BossW:SetTestMode(count); refreshTestBtns() end)
        addTooltip(b, count == 0 and L["Stop the simulation."]
            or format(L["Simulate %d boss frame(s) with fake HP, casts and auras."], count))
        testBtns[#testBtns + 1] = b
        _registerInSection(b)
        xs = xs + 38
    end
    refreshTestBtns()

    -- ============ GENERAL ============
    y = y - 36
    makeSection(page, L["General"], 14, y, "layout.general"); y = y - 24

    addTooltip(makeCheck(page, L["Enable"], "enabled", 14, y),
        L["Master switch for the addon. When off, BossWatch frames stay hidden."])
    addTooltip(makeCheck(page, L["Hide Blizzard"], "hideBlizzard", 184, y),
        L["Hide the default Blizzard boss frames."])

    -- Minimap icon checkbox (account-wide, not per-profile)
    local cbMini = CreateFrame("CheckButton", "BWOpt_minimapIcon", page, "UICheckButtonTemplate")
    cbMini:SetSize(24, 24)
    cbMini.Text:SetFontObject("GameFontHighlight")
    cbMini:SetPoint("TOPLEFT", page, "TOPLEFT", 360, y)
    cbMini.Text:SetText(L["Show minimap icon"])
    cbMini:SetChecked(BossWatchDB and BossWatchDB.minimap and not BossWatchDB.minimap.hide)
    cbMini:SetScript("OnClick", function(self)
        if BossW.ToggleMinimapIcon then BossW:ToggleMinimapIcon(self:GetChecked() and true or false) end
    end)
    cbMini.refresh = function()
        cbMini:SetChecked(BossWatchDB and BossWatchDB.minimap and not BossWatchDB.minimap.hide)
    end
    addTooltip(cbMini, L["Show a minimap button to open the options. Left-click: options, right-click: toggle mover."])
    _registerInSection(cbMini)

    y = y - 30
    addTooltip(markAsNew(makeCheck(page, L["Click actions on boss frames"], "clickActions", 14, y), "clickActions"),
        L["Enable modifier+click shortcuts on boss frames: Shift+Click cycles a raid marker, Ctrl+Click sets focus."])

    -- ============ LAYOUT STYLE ============
    y = y - 60
    makeSection(page, L["Layout style"], 14, y, "layout.style"); y = y - 24

    addTooltip(markAsNew(makeDropdown(page, L["Layout"], "layoutBlocks", {
        { text = L["3 blocks (compact)"],     value = 3 },
        { text = L["4 blocks (name on top)"], value = 4 },
    }, 14, y, 200), "layoutBlocks"),
        L["3 blocks: name is overlaid on the HP bar (compact). 4 blocks: name has its own dedicated row above the HP bar (more readable)."])
    addTooltip(makeDropdown(page, L["Portrait Position"], "portraitPosition", {
        { text = L["Left"], value = "LEFT" },
        { text = L["Right"], value = "RIGHT" },
        { text = L["Hidden"], value = "HIDDEN" },
    }, 260, y), L["Where the boss portrait icon is shown on the frame."])
    y = y - 56
    addTooltip(makeSlider(page, L["Portrait Size"], "portraitSize", 20, 80, 1, 14, y),
        L["Size of the boss portrait icon in pixels."])

    -- ============ POSITION ============
    y = y - 60
    makeSection(page, L["Position"], 14, y, "layout.position"); y = y - 24

    addTooltip(makeDropdown(page, L["Anchor"], "anchor", ANCHOR9(), 14, y),
        L["Anchor point on the screen used as origin for the X/Y offsets."])
    addTooltip(makeDropdown(page, L["Grow Direction"], "growDirection", {
        { text = L["Down"], value = "DOWN" }, { text = L["Up"], value = "UP" },
    }, 184, y), L["Direction the additional boss frames stack from the first one."])
    y = y - 56
    addTooltip(makeSlider(page, L["Offset X"], "anchorX", -1500, 1500, 1, 14, y),
        L["Horizontal offset from the anchor point."])
    addTooltip(makeSlider(page, L["Offset Y"], "anchorY", -1500, 1500, 1, 260, y),
        L["Vertical offset from the anchor point."])

    -- ============ DIMENSIONS ============
    y = y - 60
    makeSection(page, L["Dimensions"], 14, y, "layout.dimensions"); y = y - 24

    addTooltip(makeSlider(page, L["Width"],  "frameWidth",  100, 400, 1, 14, y),
        L["Width of each boss frame in pixels."])
    addTooltip(makeSlider(page, L["Total height"], "frameHeight",  20, 120, 1, 260, y),
        L["Total height of each boss frame in pixels. The HP bar fills whatever space is left after the power and cast bars."])
    y = y - 56
    addTooltip(makeSlider(page, L["Spacing"], "frameSpacing", 0, 40, 1, 14, y),
        L["Vertical gap between stacked boss frames."])
    addTooltip(makeSlider(page, L["Scale"],  "frameScale", 0.5, 2.0, 0.05, 260, y),
        L["Overall scale of all boss frames."])

    -- ============ TARGET HIGHLIGHT ============
    y = y - 60
    makeSection(page, L["Target Highlight"], 14, y, "layout.targetHL"); y = y - 24

    addTooltip(markAsNew(makeCheck(page, L["Highlight current target"], "targetHighlight", 14, y), "targetHighlight"),
        L["Add a colored border around the boss frame matching your current target."])
    addTooltip(markAsNew(makeCheck(page, L["Animate (pulse)"], "targetHighlightAnimate", 184, y), "targetHighlightAnimate"),
        L["Pulsing animation on the highlight border."])
    addTooltip(markAsNew(makeSlider(page, L["Thickness"], "targetHighlightThickness", 1, 6, 1, 354, y, 130), "targetHighlightThickness"),
        L["Border thickness of the highlight in pixels."])
    y = y - 56

    addTooltip(markAsNew(makeDropdown(page, L["Color mode"], "targetHighlightColorMode", {
        { text = L["Static"],         value = "STATIC" },
        { text = L["Class color"],    value = "CLASS" },
        { text = L["Reaction"],       value = "REACTION" },
    }, 14, y, 180), "targetHighlightColorMode"),
        L["How the highlight border is colored: fixed color, target's class, or reaction."])
    addTooltip(markAsNew(makeColorPicker(page, L["Static color"], "targetHighlightColor", 280, y), "targetHighlightColor"),
        L["Fixed color used when the mode above is set to 'Static'."])
end
