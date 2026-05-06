local addonName, BW = ...

local CreateFrame = CreateFrame
local pairs, ipairs = pairs, ipairs

local panel
local refresh = function() if BW.RefreshAll then BW:RefreshAll() end end

-- ============================================================
-- WIDGET FACTORIES
-- ============================================================

local function makeSlider(parent, label, key, minV, maxV, step, x, y, width)
    local sl = CreateFrame("Slider", "BWOpt_"..key, parent, "OptionsSliderTemplate")
    sl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    sl:SetWidth(width or 180)
    sl:SetMinMaxValues(minV, maxV)
    sl:SetValueStep(step)
    sl:SetObeyStepOnDrag(true)
    _G[sl:GetName().."Low"]:SetText(""); _G[sl:GetName().."High"]:SetText("")
    _G[sl:GetName().."Text"]:SetText(label)

    local edit = CreateFrame("EditBox", nil, sl, "InputBoxTemplate")
    edit:SetSize(46, 18)
    edit:SetPoint("LEFT", sl, "RIGHT", 8, 0)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlightSmall")
    sl.edit = edit
    sl.dbKey = key

    sl:SetScript("OnValueChanged", function(self, val)
        if step < 1 then val = math.floor(val * 100 + 0.5) / 100
        else val = math.floor(val + 0.5) end
        local db = BW:GetDB()
        db[key] = val
        edit:SetText(tostring(val))
        refresh()
    end)
    edit:SetScript("OnEnterPressed", function(self)
        local v = tonumber(self:GetText())
        if v then sl:SetValue(v) end
        self:ClearFocus()
    end)
    return sl
end

local function makeCheck(parent, label, key, x, y)
    local cb = CreateFrame("CheckButton", "BWOpt_"..key, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb.Text:SetText(label)
    cb.dbKey = key
    cb:SetScript("OnClick", function(self)
        BW:GetDB()[key] = self:GetChecked() and true or false
        refresh()
    end)
    return cb
end

local function makeDropdown(parent, label, key, options, x, y, width)
    local labelFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelFS:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    labelFS:SetText(label)

    local dd = CreateFrame("Frame", "BWOpt_DD_"..key, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", labelFS, "BOTTOMLEFT", -18, -2)
    UIDropDownMenu_SetWidth(dd, width or 130)
    dd.dbKey = key
    dd._options = options

    local function setSelected(val, text)
        BW:GetDB()[key] = val
        UIDropDownMenu_SetText(dd, text)
        refresh()
    end

    UIDropDownMenu_Initialize(dd, function()
        for _, opt in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.text
            info.value = opt.value
            info.func = function() setSelected(opt.value, opt.text) end
            info.checked = (BW:GetDB()[key] == opt.value)
            UIDropDownMenu_AddButton(info)
        end
    end)
    dd.refresh = function()
        local cur = BW:GetDB()[key]
        for _, opt in ipairs(options) do
            if opt.value == cur then UIDropDownMenu_SetText(dd, opt.text); return end
        end
    end
    return dd
end

local function ANCHOR9()
    return {
        { text = "Top Left",     value = "TOPLEFT" },
        { text = "Top",          value = "TOP" },
        { text = "Top Right",    value = "TOPRIGHT" },
        { text = "Left",         value = "LEFT" },
        { text = "Center",       value = "CENTER" },
        { text = "Right",        value = "RIGHT" },
        { text = "Bottom Left",  value = "BOTTOMLEFT" },
        { text = "Bottom",       value = "BOTTOM" },
        { text = "Bottom Right", value = "BOTTOMRIGHT" },
    }
end

-- ============================================================
-- TABS
-- ============================================================

local function makeTab(parent, id, label, idx)
    local tab = CreateFrame("Button", "BWTab"..id, parent, "BackdropTemplate")
    tab:SetSize(80, 22)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", 8 + (idx - 1) * 84, -28)
    tab:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    tab:SetBackdropColor(0.12, 0.12, 0.14, 1)
    tab:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER")
    text:SetText(label)
    tab.text = text
    tab.id = id
    return tab
end

-- ============================================================
-- PAGE BUILDERS
-- ============================================================

local function buildLayoutPage(page)
    local y = -10
    local btnMover = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnMover:SetSize(160, 22); btnMover:SetPoint("TOPLEFT", 14, y)
    btnMover:SetText("Unlock / Lock Mover")
    btnMover:SetScript("OnClick", function() BW:ToggleMover() end)
    local btnTest = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnTest:SetSize(160, 22); btnTest:SetPoint("TOPLEFT", 184, y)
    btnTest:SetText("Toggle Test (3 bosses)")
    btnTest:SetScript("OnClick", function()
        local any
        for i = 1, 5 do if BW.BossFrames[i] and BW.BossFrames[i]._testMode then any = true; break end end
        BW:SetTestMode(any and 0 or 3)
    end)

    y = y - 30
    makeCheck(page, "Enable", "enabled", 14, y); makeCheck(page, "Hide Blizzard", "hideBlizzard", 184, y)
    y = y - 26
    makeDropdown(page, "Anchor", "anchor", ANCHOR9(), 14, y); makeDropdown(page, "Grow Direction", "growDirection", {
        { text = "Down", value = "DOWN" }, { text = "Up", value = "UP" },
    }, 184, y)
    y = y - 50
    makeSlider(page, "Offset X", "anchorX", -1500, 1500, 1, 14, y)
    makeSlider(page, "Offset Y", "anchorY", -1500, 1500, 1, 244, y)
    y = y - 50
    makeSlider(page, "Width",   "frameWidth",   100, 400, 1, 14, y)
    makeSlider(page, "Height",  "frameHeight",   20, 100, 1, 244, y)
    y = y - 50
    makeSlider(page, "Spacing", "frameSpacing",  0,  40, 1,  14, y)
    makeSlider(page, "Scale",   "frameScale",  0.5, 2.0, 0.05, 244, y)
    y = y - 50
    makeDropdown(page, "Portrait Position", "portraitPosition", {
        { text = "Left", value = "LEFT" },
        { text = "Right", value = "RIGHT" },
        { text = "Hidden", value = "HIDDEN" },
    }, 14, y)
    makeSlider(page, "Portrait Size", "portraitSize", 20, 80, 1, 244, y)
end

local function buildBarsPage(page)
    local y = -10
    makeCheck(page, "Show Power Bar", "showPowerBar", 14, y)
    makeSlider(page, "Power Bar Height", "powerBarHeight", 2, 20, 1, 184, y)
    y = y - 50
    makeDropdown(page, "Health Color", "healthColorMode", {
        { text = "Reaction (Blizzard)", value = "REACTION" },
        { text = "Class fallback",      value = "CLASS_FALLBACK" },
        { text = "Custom static",       value = "STATIC" },
    }, 14, y, 180)
    y = y - 50
    makeSlider(page, "HP background alpha", "healthBackgroundAlpha", 0, 1, 0.05, 14, y)
    makeSlider(page, "Power background alpha", "powerBackgroundAlpha", 0, 1, 0.05, 244, y)
end

local function buildCastPage(page)
    local y = -10
    makeCheck(page, "Show Cast Bar", "showCastBar", 14, y)
    makeCheck(page, "Detached", "castBarDetached", 184, y)
    y = y - 26
    makeSlider(page, "Cast Bar Height", "castBarHeight", 8, 40, 1, 14, y)
    makeDropdown(page, "Icon Position", "castBarIconPosition", {
        { text = "Left", value = "LEFT" }, { text = "Right", value = "RIGHT" },
    }, 244, y)
    y = y - 50
    makeSlider(page, "Cast bg alpha", "castBackgroundAlpha", 0, 1, 0.05, 14, y)
    y = y - 50
    makeDropdown(page, "Detached Anchor", "castBarDetachedAnchor", ANCHOR9(), 14, y)
    makeSlider(page, "Detached Width (0=auto)", "castBarDetachedWidth", 0, 400, 1, 244, y)
    y = y - 50
    makeSlider(page, "Detached Offset X", "castBarDetachedX", -200, 200, 1, 14, y)
    makeSlider(page, "Detached Offset Y", "castBarDetachedY", -200, 200, 1, 244, y)
end

local function buildTextPage(page)
    local y = -10
    makeCheck(page, "Show Name", "showName", 14, y)
    makeDropdown(page, "Name Position", "nameAnchor", ANCHOR9(), 184, y)
    y = y - 50
    makeSlider(page, "Name Offset X", "nameX", -80, 80, 1, 14, y)
    makeSlider(page, "Name Offset Y", "nameY", -80, 80, 1, 244, y)
    y = y - 50
    makeSlider(page, "Name max length (0=off)", "nameMaxLength", 0, 40, 1, 14, y, 250)
    y = y - 40

    makeCheck(page, "Show Health Text", "showHealthText", 14, y)
    makeDropdown(page, "HP text position", "healthTextAnchor", ANCHOR9(), 184, y)
    y = y - 50
    makeSlider(page, "HP text Offset X", "healthTextX", -80, 80, 1, 14, y)
    makeSlider(page, "HP text Offset Y", "healthTextY", -80, 80, 1, 244, y)
    y = y - 50
    makeDropdown(page, "HP format", "healthTextFormat", {
        { text = "Percent (50%)",     value = "PERCENT" },
        { text = "Current (50M)",      value = "CURRENT" },
        { text = "Current + Percent",  value = "CURRENT_PERCENT" },
        { text = "Current / Max",      value = "CURRENT_MAX" },
    }, 14, y, 200)

    y = y - 50
    makeCheck(page, "Show Power Text", "showPowerText", 14, y)
    makeDropdown(page, "Power format", "powerTextFormat", {
        { text = "Percent (50%)",     value = "PERCENT" },
        { text = "Current (50M)",      value = "CURRENT" },
        { text = "Current + Percent",  value = "CURRENT_PERCENT" },
        { text = "Current / Max",      value = "CURRENT_MAX" },
    }, 184, y, 200)
    y = y - 50
    makeCheck(page, "Show Raid Target Icon", "showRaidTargetIcon", 14, y)
    makeSlider(page, "Raid icon size", "raidTargetSize", 10, 48, 1, 244, y)
end

local function buildAurasPage(page)
    local y = -10
    makeCheck(page, "Show Auras", "showAuras", 14, y)
    makeDropdown(page, "Filter", "aurasFilter", {
        { text = "Debuffs (HARMFUL)", value = "HARMFUL" },
        { text = "Buffs (HELPFUL)",   value = "HELPFUL" },
    }, 184, y)
    y = y - 50
    makeDropdown(page, "Source", "aurasSource", {
        { text = "All (Blizzard-like)", value = "ALL" },
        { text = "Only mine",           value = "MINE" },
        { text = "Hide mine",           value = "NOT_MINE" },
        { text = "Boss-cast only",      value = "BOSS_ONLY" },
    }, 14, y, 180)
    y = y - 50
    makeSlider(page, "Max Count", "aurasMaxCount", 1, 8, 1, 14, y)
    makeSlider(page, "Size", "aurasSize", 12, 48, 1, 244, y)
    y = y - 50
    makeSlider(page, "Spacing", "aurasSpacing", 0, 10, 1, 14, y)
    y = y - 40
    makeCheck(page, "Show Stacks", "aurasShowStacks", 14, y)
    makeCheck(page, "Show Timer",  "aurasShowTimer",  184, y)
    y = y - 26
    makeDropdown(page, "Anchor", "aurasAnchor", ANCHOR9(), 14, y)
    makeDropdown(page, "Grow X", "aurasGrowX", {
        { text = "Left",  value = "LEFT" },
        { text = "Right", value = "RIGHT" },
    }, 244, y)
    y = y - 50
    makeSlider(page, "Offset X", "aurasX", -200, 200, 1, 14, y)
    makeSlider(page, "Offset Y", "aurasY", -200, 200, 1, 244, y)
    y = y - 50
    makeDropdown(page, "Timer Placement", "aurasTimerPlacement", {
        { text = "Inside (centered)", value = "INSIDE" },
        { text = "Below icon",        value = "BELOW" },
        { text = "Above icon",        value = "ABOVE" },
    }, 14, y)
end

-- ============================================================
-- BUILD
-- ============================================================

local function build()
    panel = CreateFrame("Frame", "BossWatchOptions", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(560, 540)
    panel:SetPoint("CENTER")
    panel:SetMovable(true); panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetFrameStrata("HIGH")
    panel:Hide()
    panel.TitleText:SetText("BossWatch — Options")

    local pageHolder = CreateFrame("Frame", nil, panel)
    pageHolder:SetPoint("TOPLEFT", 4, -56)
    pageHolder:SetPoint("BOTTOMRIGHT", -4, 4)

    local pages = {}
    local function newPage()
        local p = CreateFrame("Frame", nil, pageHolder)
        p:SetAllPoints(pageHolder)
        p:Hide()
        return p
    end

    pages.layout = newPage(); buildLayoutPage(pages.layout)
    pages.bars   = newPage(); buildBarsPage(pages.bars)
    pages.cast   = newPage(); buildCastPage(pages.cast)
    pages.text   = newPage(); buildTextPage(pages.text)
    pages.auras  = newPage(); buildAurasPage(pages.auras)

    local tabs = {
        { id = "layout", label = "Layout" },
        { id = "bars",   label = "Bars" },
        { id = "cast",   label = "Cast Bar" },
        { id = "text",   label = "Text" },
        { id = "auras",  label = "Auras" },
    }
    local tabBtns = {}
    local function selectTab(id)
        for _, p in pairs(pages) do p:Hide() end
        if pages[id] then pages[id]:Show() end
        for _, t in ipairs(tabBtns) do
            if t.id == id then
                t:SetBackdropColor(0.25, 0.18, 0.05, 1)
                t:SetBackdropBorderColor(1, 0.82, 0, 1)
                t.text:SetTextColor(1, 0.82, 0)
            else
                t:SetBackdropColor(0.12, 0.12, 0.14, 1)
                t:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                t.text:SetTextColor(0.8, 0.8, 0.8)
            end
        end
    end

    for i, t in ipairs(tabs) do
        local b = makeTab(panel, t.id, t.label, i)
        b:SetScript("OnClick", function() selectTab(t.id) end)
        tabBtns[#tabBtns + 1] = b
    end

    panel.refreshAll = function()
        local db = BW:GetDB()
        local function walk(f)
            for _, child in ipairs({f:GetChildren()}) do
                if child.dbKey then
                    if child.SetChecked then
                        child:SetChecked(db[child.dbKey] and true or false)
                    elseif child.SetValue and child.edit then
                        child:SetValue(db[child.dbKey] or 0)
                        child.edit:SetText(tostring(db[child.dbKey] or 0))
                    elseif child.refresh then
                        child:refresh()
                    end
                end
                walk(child)
            end
        end
        walk(pageHolder)
    end

    selectTab("layout")
end

function BW:ToggleOptions()
    if not panel then build() end
    if panel:IsShown() then panel:Hide()
    else panel.refreshAll(); panel:Show() end
end
