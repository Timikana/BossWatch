local addonName, BW = ...
local L = BW.L

local CreateFrame = CreateFrame
local pairs, ipairs = pairs, ipairs

local panel
local refresh = function() if BW.RefreshAll then BW:RefreshAll() end end

-- Module-level pointer used by widget factories to auto-register with the
-- currently-being-built section. Each makeSection() updates this; each
-- makeXxx() factory pushes itself onto _currentSection.children/dbKeys.
local _currentSection = nil
local function _registerInSection(widget, dbKey)
    if _currentSection and widget then
        _currentSection.children[#_currentSection.children + 1] = widget
        if dbKey then _currentSection.dbKeys[#_currentSection.dbKeys + 1] = dbKey end
    end
end

-- ============================================================
-- "NEW" BADGE
-- ============================================================
local function markAsNew(widget, dbKey)
    if not dbKey or not widget then return widget end
    BossWatchDB = BossWatchDB or {}
    BossWatchDB.seenFeatures = BossWatchDB.seenFeatures or {}
    if BossWatchDB.seenFeatures[dbKey] then return widget end

    -- Badge container
    local badge = CreateFrame("Frame", nil, widget, "BackdropTemplate")
    badge:SetSize(38, 16)
    badge:SetPoint("BOTTOMLEFT", widget, "TOPLEFT", -3, 1)
    badge:SetFrameLevel((widget.GetFrameLevel and widget:GetFrameLevel() or 1) + 5)
    badge:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    badge:SetBackdropColor(1, 0.6, 0, 0.85)        -- orange fill
    badge:SetBackdropBorderColor(1, 1, 0.5, 1)     -- bright yellow border

    -- Glow halo behind (additive blend, visible as a soft outer glow)
    local glow = badge:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(1, 0.85, 0, 0.9)
    glow:SetPoint("CENTER", badge, "CENTER", 0, 0)
    glow:SetSize(58, 36)

    -- Text on top
    local text = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetText("NEW")
    text:SetTextColor(1, 1, 1)
    text:SetPoint("CENTER", badge, "CENTER", 0, 0)
    text:SetShadowColor(0, 0, 0, 1)
    text:SetShadowOffset(1, -1)

    -- Pulse animation on the glow
    local ag = glow:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(1)
    a:SetToAlpha(0.3)
    a:SetDuration(0.8)
    a:SetSmoothing("IN_OUT")
    ag:Play()

    local function clear()
        BossWatchDB.seenFeatures = BossWatchDB.seenFeatures or {}
        BossWatchDB.seenFeatures[dbKey] = true
        if ag then ag:Stop() end
        badge:Hide()
    end

    widget:HookScript("OnEnter", clear)
    local typ = widget.GetObjectType and widget:GetObjectType() or ""
    if typ == "CheckButton" or typ == "Button" then
        widget:HookScript("OnClick", clear)
    elseif typ == "Slider" then
        widget:HookScript("OnValueChanged", clear)
    end
    return widget
end

-- ============================================================
-- WIDGET FACTORIES
-- ============================================================

local function makeSlider(parent, label, key, minV, maxV, step, x, y, width)
    local sl = CreateFrame("Frame", "BWOpt_"..key, parent, "MinimalSliderWithSteppersTemplate")
    sl:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    sl:SetWidth(width or 200)
    sl.dbKey = key

    local function fmt(v)
        if step < 1 then return string.format("%.2f", v) end
        return tostring(math.floor(v + 0.5))
    end

    local formatters = {
        [MinimalSliderWithSteppersMixin.Label.Min] = function() return fmt(minV) end,
        [MinimalSliderWithSteppersMixin.Label.Max] = function() return fmt(maxV) end,
        [MinimalSliderWithSteppersMixin.Label.Top] = function(v) return label .. ": " .. fmt(v) end,
    }

    local numSteps = math.max(1, math.floor((maxV - minV) / step + 0.5))
    local function readDB()
        local v = BW:GetDB()[key]
        if type(v) ~= "number" then v = minV end
        if v < minV then v = minV elseif v > maxV then v = maxV end
        return v
    end

    sl:Init(readDB(), minV, maxV, numSteps, formatters)

    local event = (MinimalSliderWithSteppersMixin.Event
        and MinimalSliderWithSteppersMixin.Event.OnValueChanged) or "OnValueChanged"
    sl:RegisterCallback(event, function(_, value)
        if step < 1 then value = math.floor(value * 100 + 0.5) / 100
        else value = math.floor(value + 0.5) end
        BW:GetDB()[key] = value
        refresh()
    end, sl)

    sl.refresh = function() sl:Init(readDB(), minV, maxV, numSteps, formatters) end
    _registerInSection(sl, key)
    return sl
end

local function makeCheck(parent, label, key, x, y)
    local cb = CreateFrame("CheckButton", "BWOpt_"..key, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(24, 24)
    cb.Text:SetFontObject("GameFontHighlight")
    cb.Text:SetText(label)
    cb.dbKey = key
    cb:SetScript("OnClick", function(self)
        BW:GetDB()[key] = self:GetChecked() and true or false
        refresh()
    end)
    _registerInSection(cb, key)
    return cb
end

local function makeDropdown(parent, label, key, options, x, y, width)
    local labelFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelFS:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    labelFS:SetText(label)

    -- Modern 11.0 dropdown (same template used by native Settings panels)
    local dd = CreateFrame("DropdownButton", "BWOpt_DD_"..key, parent, "WowStyle1DropdownTemplate")
    dd:SetPoint("TOPLEFT", labelFS, "BOTTOMLEFT", 0, -2)
    dd:SetWidth(width or 160)
    dd.dbKey = key
    dd._options = options

    dd:SetupMenu(function(_, rootDescription)
        for _, opt in ipairs(options) do
            rootDescription:CreateRadio(opt.text,
                function() return BW:GetDB()[key] == opt.value end,
                function()
                    BW:GetDB()[key] = opt.value
                    refresh()
                end)
        end
    end)
    dd.refresh = function() dd:GenerateMenu() end
    dd._labelFS = labelFS
    _registerInSection(dd, key)
    _registerInSection(labelFS)
    return dd
end

local POPUP_ITEM_H = 22
local POPUP_VISIBLE = 12

local function makeMediaDropdown(parent, label, key, mediaType, x, y, width, tint)
    width = width or 180
    -- tint = {r,g,b} optional preview color. nil = no tint (show texture as-is).
    local TR, TG, TB = 1, 1, 1
    if tint then TR, TG, TB = tint[1] or 1, tint[2] or 1, tint[3] or 1 end

    local labelFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelFS:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    labelFS:SetText(label)

    -- Anchor button (acts as the dropdown header) — modern dark style
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 24)
    btn:SetPoint("TOPLEFT", labelFS, "BOTTOMLEFT", 0, -4)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.06, 0.06, 0.08, 1)
    btn:SetBackdropBorderColor(0.35, 0.35, 0.40, 1)
    btn:HookScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 0.82, 0, 1)
    end)
    btn:HookScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.35, 0.35, 0.40, 1)
    end)
    btn.dbKey = key

    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btnText:SetPoint("LEFT", btn, "LEFT", 6, 0)
    btnText:SetPoint("RIGHT", btn, "RIGHT", -16, 0)
    btnText:SetJustifyH("LEFT")

    local arrow = btn:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    arrow:SetSize(14, 14)
    arrow:SetPoint("RIGHT", btn, "RIGHT", -2, 0)

    -- External preview to the right
    local previewBg = parent:CreateTexture(nil, "BACKGROUND")
    previewBg:SetPoint("LEFT", btn, "RIGHT", 12, 0)
    previewBg:SetSize(width + 30, 18)
    previewBg:SetColorTexture(0, 0, 0, 0.7)

    local previewBorder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    previewBorder:SetPoint("TOPLEFT", previewBg, "TOPLEFT", -1, 1)
    previewBorder:SetPoint("BOTTOMRIGHT", previewBg, "BOTTOMRIGHT", 1, -1)
    previewBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    previewBorder:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local previewTex, previewText
    if mediaType == "font" then
        previewText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        previewText:SetPoint("CENTER", previewBg, "CENTER", 0, 0)
        previewText:SetText("AaBb 123")
        previewText:SetTextColor(1, 0.82, 0)
    else
        previewTex = parent:CreateTexture(nil, "ARTWORK")
        previewTex:SetPoint("TOPLEFT", previewBg, "TOPLEFT", 1, -1)
        previewTex:SetPoint("BOTTOMRIGHT", previewBg, "BOTTOMRIGHT", -1, 1)
    end

    local function applyPreview(name)
        if mediaType == "font" then
            pcall(previewText.SetFont, previewText, BW:ResolveFont(name), 13, "")
        else
            previewTex:SetTexture(BW:ResolveTexture(name))
            previewTex:SetVertexColor(TR, TG, TB, 1)
        end
    end

    local function listMedia()
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        if LSM then return LSM:List(mediaType) end
        return { "Blizzard" }
    end

    -- Custom scrollable popup
    local popupW = width + 40
    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetSize(popupW, POPUP_ITEM_H * POPUP_VISIBLE + 12)
    popup:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    popup:SetBackdropColor(0.03, 0.03, 0.05, 0.98)
    popup:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
    popup:Hide()
    popup:EnableMouse(true)

    local scroll = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", popup, "TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(popupW - 36, 10)
    scroll:SetScrollChild(content)

    -- Click-outside catcher
    local catcher = CreateFrame("Button", nil, UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:SetFrameLevel(1)
    catcher:RegisterForClicks("AnyUp")
    catcher:Hide()
    catcher:SetScript("OnClick", function() popup:Hide() end)
    popup:HookScript("OnShow", function()
        catcher:Show()
        popup:SetFrameLevel(catcher:GetFrameLevel() + 10)
    end)
    popup:HookScript("OnHide", function() catcher:Hide() end)

    local itemPool = {}
    local function getItem(i)
        if itemPool[i] then return itemPool[i] end
        local it = CreateFrame("Button", nil, content)
        it:SetHeight(POPUP_ITEM_H)
        it:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -(i - 1) * POPUP_ITEM_H)
        it:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(i - 1) * POPUP_ITEM_H)

        local hl = it:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints(it)
        hl:SetColorTexture(1, 0.82, 0, 0.18)
        hl:Hide()
        it:SetScript("OnEnter", function() hl:Show() end)
        it:SetScript("OnLeave", function() hl:Hide() end)

        if mediaType == "font" then
            local fs = it:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            fs:SetPoint("LEFT", it, "LEFT", 8, 0)
            fs:SetPoint("RIGHT", it, "RIGHT", -8, 0)
            fs:SetJustifyH("LEFT")
            it.fs = fs
        else
            local barBg = it:CreateTexture(nil, "BACKGROUND", nil, 1)
            barBg:SetPoint("LEFT", it, "LEFT", 6, 0)
            barBg:SetPoint("RIGHT", it, "RIGHT", -6, 0)
            barBg:SetHeight(16)
            barBg:SetColorTexture(0, 0, 0, 0.6)
            local bar = it:CreateTexture(nil, "ARTWORK")
            bar:SetPoint("TOPLEFT", barBg, "TOPLEFT", 1, -1)
            bar:SetPoint("BOTTOMRIGHT", barBg, "BOTTOMRIGHT", -1, 1)
            local nameFS = it:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameFS:SetPoint("LEFT", barBg, "LEFT", 6, 0)
            nameFS:SetTextColor(1, 1, 1, 1)
            it.bar = bar
            it.nameFS = nameFS
        end
        itemPool[i] = it
        return it
    end

    local function rebuild()
        local list = listMedia()
        for i, name in ipairs(list) do
            local it = getItem(i)
            it:Show()
            if mediaType == "font" then
                pcall(it.fs.SetFont, it.fs, BW:ResolveFont(name), 13, "")
                it.fs:SetText(name)
            else
                it.bar:SetTexture(BW:ResolveTexture(name))
                it.bar:SetVertexColor(TR, TG, TB, 1)
                it.nameFS:SetText(name)
            end
            it:SetScript("OnClick", function()
                BW:GetDB()[key] = name
                btnText:SetText(name)
                applyPreview(name)
                popup:Hide()
                refresh()
            end)
        end
        for i = #list + 1, #itemPool do itemPool[i]:Hide() end
        content:SetHeight(math.max(POPUP_ITEM_H, #list * POPUP_ITEM_H))
    end

    btn:SetScript("OnClick", function()
        if popup:IsShown() then
            popup:Hide()
        else
            rebuild()
            popup:ClearAllPoints()
            popup:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
            popup:Show()
        end
    end)

    btn.refresh = function()
        local cur = BW:GetDB()[key] or "Blizzard"
        btnText:SetText(cur)
        applyPreview(cur)
    end
    btn.refresh()
    -- Register all the sibling regions of the media dropdown so that collapsing
    -- the section hides the label and the preview as well, not just the button.
    _registerInSection(btn, key)
    _registerInSection(labelFS)
    _registerInSection(previewBg)
    _registerInSection(previewBorder)
    if previewTex then _registerInSection(previewTex) end
    if previewText then _registerInSection(previewText) end
    return btn
end

local function makeColorPicker(parent, label, dbKey, x, y)
    local lab
    if label and label ~= "" then
        lab = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lab:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        lab:SetText(label)
    end

    -- Modern compact swatch button: gold thin border + inner color swatch
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(28, 22)
    if lab then
        btn:SetPoint("TOPLEFT", lab, "BOTTOMLEFT", 0, -2)
    else
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    end
    btn:RegisterForClicks("AnyUp")

    local border = btn:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints(btn)
    border:SetColorTexture(0.55, 0.45, 0.10, 1)

    local swatch = btn:CreateTexture(nil, "ARTWORK")
    swatch:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    swatch:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    swatch:SetColorTexture(1, 1, 1, 1)

    btn:SetScript("OnEnter", function(self)
        border:SetColorTexture(1, 0.82, 0, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Click to choose a color"], 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        border:SetColorTexture(0.55, 0.45, 0.10, 1)
        GameTooltip:Hide()
    end)

    local function getColor()
        return BW:GetDB()[dbKey] or { r = 1, g = 1, b = 1, a = 1 }
    end
    local function refreshSwatch()
        local c = getColor()
        swatch:SetVertexColor(c.r, c.g, c.b, c.a or 1)
    end
    btn.refresh = refreshSwatch
    refreshSwatch()

    btn:SetScript("OnClick", function()
        local c = getColor()
        local function setColor(r, g, b, a)
            BW:GetDB()[dbKey] = { r = r, g = g, b = b, a = a or 1 }
            refreshSwatch()
            refresh()
        end
        local function readAlpha()
            -- Modern API: ColorPickerFrame:GetColorAlpha(). Fallback to OpacitySliderFrame.
            if ColorPickerFrame.GetColorAlpha then
                return ColorPickerFrame:GetColorAlpha() or 1
            elseif OpacitySliderFrame and OpacitySliderFrame:IsShown() then
                return OpacitySliderFrame:GetValue()
            end
            return 1
        end
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                hasOpacity = true,
                opacity = c.a or 1,
                r = c.r, g = c.g, b = c.b,
                swatchFunc = function()
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    setColor(r, g, b, readAlpha())
                end,
                opacityFunc = function()
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    setColor(r, g, b, readAlpha())
                end,
                cancelFunc = function(prev)
                    setColor(prev.r, prev.g, prev.b, prev.opacity or 1)
                end,
            })
        else
            ColorPickerFrame:SetColorRGB(c.r, c.g, c.b)
            ColorPickerFrame.hasOpacity = true
            ColorPickerFrame.opacity = c.a or 1
            ColorPickerFrame.previousValues = { r = c.r, g = c.g, b = c.b, opacity = c.a or 1 }
            ColorPickerFrame.func = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                setColor(r, g, b, ColorPickerFrame.opacity or 1)
            end
            ColorPickerFrame.opacityFunc = ColorPickerFrame.func
            ColorPickerFrame.cancelFunc = function(prev)
                setColor(prev.r, prev.g, prev.b, prev.opacity or 1)
            end
            ColorPickerFrame:Hide()
            ColorPickerFrame:Show()
        end
    end)

    btn.dbKey = dbKey
    _registerInSection(btn, dbKey)
    if lab then _registerInSection(lab) end
    return btn
end

-- Section header with title + thin gold separator line.
-- Both line endpoints MUST be anchored at the same vertical pixel — anchors that
-- mix "header:RIGHT" (mid of header) with "parent:RIGHT" (mid of parent) produce
-- a diagonal that renders as variable thickness or invisible.
-- Solution: defer positioning by one tick, then anchor both endpoints to
-- parent:TOPLEFT / parent:TOPRIGHT at the exact same y, with the line's left
-- offset computed from the actual rendered header width.
-- Helper: shallow-deep copy a value so default tables (e.g. color = {r,g,b,a})
-- aren't shared between profiles when reset.
local function _cloneDefault(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, val in pairs(v) do out[k] = _cloneDefault(val) end
    return out
end

local function makeSection(parent, title, x, y, key)
    local section = {
        children = {},
        dbKeys = {},
        key = key,
    }

    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    header:SetTextColor(1, 0.82, 0)
    section.header = header

    header:SetText(title)

    -- Chevron (collapsed indicator) shown to the RIGHT of the title
    local chevron = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chevron:SetPoint("LEFT", header, "RIGHT", 4, 0)
    chevron:SetTextColor(1, 0.82, 0)
    chevron:SetText("")  -- set by SetCollapsed
    section.chevron = chevron

    -- Invisible click area covering the header + a slice of the divider line
    local clickArea = CreateFrame("Button", nil, parent)
    clickArea:SetPoint("TOPLEFT",  parent, "TOPLEFT", x - 14, y + 4)
    clickArea:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -40,   y + 4)
    clickArea:SetHeight(18)
    clickArea:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    section.clickArea = clickArea

    -- Reset section button (small ↺) on the right side of the divider
    local btnReset = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btnReset:SetSize(20, 18)
    btnReset:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, y + 2)
    btnReset:SetText("↺")
    section.resetBtn = btnReset

    local line = parent:CreateTexture(nil, "OVERLAY")
    line:SetHeight(1)
    line:SetColorTexture(1, 0.82, 0, 0.55)
    section.line = line

    local function place()
        local hw = header:GetStringWidth() or 0
        local cw = chevron:GetStringWidth() or 0
        local startX = x + hw + (cw > 0 and (4 + cw) or 0) + 10
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT",  parent, "TOPLEFT",  startX, y - 7)
        line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -42,    y - 7)
    end

    function section:SetCollapsed(state, persist)
        state = state and true or false
        for _, w in ipairs(self.children) do
            if state then
                if w.Hide then w:Hide() end
            else
                if w.Show then w:Show() end
            end
            -- The dropdown's external label is registered separately; nothing
            -- special needed here, the loop hides/shows it like everything else.
        end
        chevron:SetText(state and "▸" or "▾")
        if persist and self.key then
            BossWatchDB = BossWatchDB or {}
            BossWatchDB.collapsedSections = BossWatchDB.collapsedSections or {}
            BossWatchDB.collapsedSections[self.key] = state or nil
        end
        self._collapsed = state
    end

    function section:Toggle()
        self:SetCollapsed(not self._collapsed, true)
    end

    function section:ResetToDefaults()
        local db = BW:GetDB()
        for _, k in ipairs(self.dbKeys) do
            local def = (BW.Defaults or {})[k]
            if def ~= nil then db[k] = _cloneDefault(def) end
        end
        if BW.RefreshAll then BW:RefreshAll() end
        if BW.ApplyFonts then BW:ApplyFonts() end
        if panel and panel.refreshAll then panel.refreshAll() end
    end

    clickArea:SetScript("OnClick", function() section:Toggle() end)
    btnReset:SetScript("OnClick", function() section:ResetToDefaults() end)

    -- Initial collapsed state from DB
    BossWatchDB = BossWatchDB or {}
    local restored = BossWatchDB.collapsedSections and key and BossWatchDB.collapsedSections[key]
    section:SetCollapsed(restored or false, false)

    -- Always include the section's own visual elements so they hide too when
    -- the user collapses upstream sections. Header + line stay visible always
    -- (clickable), so we DON'T register them.
    -- chevron stays visible (shows state).
    -- btnReset stays visible (lets user reset even when collapsed).

    place()
    C_Timer.After(0, place)

    -- Tooltips on the header + reset
    if addTooltip then
        addTooltip(clickArea, L["Click to collapse/expand this section."])
        addTooltip(btnReset,  L["Reset this section to default values."])
    end

    -- This section is now the active one; subsequent makeXxx widgets register here.
    _currentSection = section
    return section
end

-- Hover tooltip helper. Hooks the widget AND any well-known child controls
-- (slider thumb, steppers) so the tooltip shows everywhere on composite widgets.
local function addTooltip(widget, text)
    if not widget or not text or text == "" then return widget end
    local function show(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(text, 1, 1, 1, true)
        GameTooltip:Show()
    end
    local function hide() GameTooltip:Hide() end

    local function hook(f)
        if not f or not f.HookScript then return end
        f:HookScript("OnEnter", show)
        f:HookScript("OnLeave", hide)
    end

    hook(widget)
    -- MinimalSliderWithSteppersTemplate exposes Slider, Back, Forward children
    hook(widget.Slider)
    hook(widget.Back)
    hook(widget.Forward)
    return widget
end

local function ANCHOR9()
    return {
        { text = L["Top Left"],     value = "TOPLEFT" },
        { text = L["Top"],          value = "TOP" },
        { text = L["Top Right"],    value = "TOPRIGHT" },
        { text = L["Left"],         value = "LEFT" },
        { text = L["Center"],       value = "CENTER" },
        { text = L["Right"],        value = "RIGHT" },
        { text = L["Bottom Left"],  value = "BOTTOMLEFT" },
        { text = L["Bottom"],       value = "BOTTOM" },
        { text = L["Bottom Right"], value = "BOTTOMRIGHT" },
    }
end

-- ============================================================
-- TABS
-- ============================================================

local TAB_TOOLTIPS = {
    layout   = L["Frame placement, dimensions, mover, test mode, target highlight."],
    bars     = L["Health, power and absorb bar textures and colors."],
    cast     = L["Cast bar texture, position, detached mode."],
    text     = L["Name, HP, power text formats, and global font."],
    raid     = L["Raid target icon (skull, cross, star...) display."],
    auras    = L["Buffs and debuffs filtering, source, layout."],
    profiles = L["Per-character profiles, import/export."],
    about    = L["Version, links, slash commands."],
}

local function makeTab(parent, id, label, idx, prevTab)
    -- Bottom-anchored tab (like Auction House / Profession panels)
    local tab = CreateFrame("Button", "BWTab"..id, parent, "PanelTabButtonTemplate")
    tab:SetText(label)
    tab.id = id
    if PanelTemplates_TabResize then PanelTemplates_TabResize(tab, 0) end
    if prevTab then
        tab:SetPoint("LEFT", prevTab, "RIGHT", 2, 0)
    else
        tab:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 12, 2)
    end
    tab.id = id
    if TAB_TOOLTIPS[id] then addTooltip(tab, TAB_TOOLTIPS[id]) end
    return tab
end

-- ============================================================
-- PAGE BUILDERS
-- ============================================================

local function buildLayoutPage(page)
    local y = -8

    -- ============ ACTIONS ============
    makeSection(page, L["Actions"], 14, y, "layout.actions"); y = y - 22

    local btnMover = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnMover:SetSize(160, 22); btnMover:SetPoint("TOPLEFT", 14, y)
    btnMover:SetText(L["Unlock / Lock Mover"])
    btnMover:SetScript("OnClick", function() BW:ToggleMover() end)
    addTooltip(btnMover, L["Toggle a draggable handle on the boss frames container so you can move it on screen."])
    _registerInSection(btnMover)

    local label = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", 184, y - 4)
    label:SetText(L["Test:"])
    _registerInSection(label)

    local function currentTestCount()
        local n = 0
        for i = 1, 5 do
            if BW.BossFrames[i] and BW.BossFrames[i]._testMode then n = n + 1 end
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
        b:SetScript("OnClick", function() BW:SetTestMode(count); refreshTestBtns() end)
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
        if BW.ToggleMinimapIcon then BW:ToggleMinimapIcon(self:GetChecked() and true or false) end
    end)
    cbMini.refresh = function()
        cbMini:SetChecked(BossWatchDB and BossWatchDB.minimap and not BossWatchDB.minimap.hide)
    end
    addTooltip(cbMini, L["Show a minimap button to open the options. Left-click: options, right-click: toggle mover."])
    _registerInSection(cbMini)

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

local function buildBarsPage(page)
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
    makeSection(page, L["Absorbs"] .. " |cffff4040(" .. (L["Experimental"] or "Experimental") .. ")|r", 14, y, "bars.absorbs"); y = y - 24
    addTooltip(markAsNew(makeCheck(page, L["Show absorbs / shields"], "showAbsorbs", 14, y), "showAbsorbs"),
        L["Display incoming damage absorbs (shields, bubbles) as a translucent overlay extending the health bar. May not show on bosses with secret-tagged values."])
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

local function buildCastPage(page)
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

local function buildTextPage(page)
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

local function buildRaidMarkerPage(page)
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

local function buildAurasPage(page)
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
    addTooltip(makeDropdown(page, L["Source"], "aurasSource", {
        { text = L["All (Blizzard-like)"], value = "ALL" },
        { text = L["Only mine"],           value = "MINE" },
        { text = L["Hide mine"],           value = "NOT_MINE" },
        { text = L["Boss-cast only"],      value = "BOSS_ONLY" },
    }, 14, y, 180), L["Filter by who applied the aura: anyone, only you, hide yours, or only boss-cast."])

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
    addTooltip(makeDropdown(page, L["Timer Placement"], "aurasTimerPlacement", {
        { text = L["Inside (centered)"], value = "INSIDE" },
        { text = L["Below icon"],        value = "BELOW" },
        { text = L["Above icon"],        value = "ABOVE" },
    }, 14, y), L["Where the timer text is positioned relative to the icon."])
end

-- ============================================================
-- PROFILES PAGE
-- ============================================================
local profileDropdownRefresh

local function showProfilePopup(title, defaultText, onAccept)
    StaticPopupDialogs["BOSSWATCH_PROFILE_PROMPT"] = {
        text = title,
        button1 = ACCEPT or "OK",
        button2 = CANCEL or "Cancel",
        hasEditBox = true,
        maxLetters = 32,
        OnShow = function(self) self.EditBox:SetText(defaultText or "") self.EditBox:HighlightText() end,
        OnAccept = function(self) onAccept(self.EditBox:GetText()) end,
        EditBoxOnEnterPressed = function(self) onAccept(self:GetText()); self:GetParent():Hide() end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopup_Show("BOSSWATCH_PROFILE_PROMPT")
end

local function showConfirmPopup(text, onAccept)
    StaticPopupDialogs["BOSSWATCH_PROFILE_CONFIRM"] = {
        text = text,
        button1 = YES or "Yes", button2 = NO or "No",
        OnAccept = onAccept,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    StaticPopup_Show("BOSSWATCH_PROFILE_CONFIRM")
end

local function buildProfilesPage(page)
    _currentSection = nil  -- this page has no makeSection — widgets shouldn't register
    local y = -10

    -- Character label
    local charLabel = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    charLabel:SetPoint("TOPLEFT", 14, y)
    charLabel:SetText(L["Character:"] .. " |cffffffff" .. (BW:GetCharKey()) .. "|r")

    y = y - 24

    -- Active profile dropdown
    local labelFS = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelFS:SetPoint("TOPLEFT", 14, y)
    labelFS:SetText(L["Active profile"])

    local dd = CreateFrame("DropdownButton", "BWOpt_DD_activeProfile", page, "WowStyle1DropdownTemplate")
    dd:SetPoint("TOPLEFT", labelFS, "BOTTOMLEFT", 0, -2)
    dd:SetWidth(220)

    dd:SetupMenu(function(_, rootDescription)
        for _, name in ipairs(BW:ListProfiles()) do
            rootDescription:CreateRadio(name,
                function() return name == BW:GetActiveProfileName() end,
                function()
                    BW:SetActiveProfile(name)
                    if panel and panel.refreshAll then panel.refreshAll() end
                end)
        end
    end)
    profileDropdownRefresh = function() dd:GenerateMenu() end
    profileDropdownRefresh()
    addTooltip(dd, L["Switch the active profile for the current character. Each character can use a different profile."])

    y = y - 56

    -- New / Reset / Delete buttons (horizontal row below the dropdown)
    local btnNew = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnNew:SetSize(110, 22)
    btnNew:SetPoint("TOPLEFT", 14, y)
    btnNew:SetText(L["New..."])
    addTooltip(btnNew, L["Create a new profile by copying the current settings."])
    btnNew:SetScript("OnClick", function()
        showProfilePopup(L["Name of the new profile (copies current settings):"], "", function(name)
            name = (name or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if name == "" then return end
            local ok = BW:CreateProfile(name)
            if ok then
                BW:SetActiveProfile(name)
                profileDropdownRefresh()
                if panel and panel.refreshAll then panel.refreshAll() end
                print("|cffeda55fBossWatch:|r " .. format(L["profile '%s' created"], name))
            end
        end)
    end)

    local btnReset = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnReset:SetSize(110, 22)
    btnReset:SetPoint("LEFT", btnNew, "RIGHT", 6, 0)
    btnReset:SetText(L["Reset"])
    addTooltip(btnReset, L["Reset the active profile to default settings."])
    btnReset:SetScript("OnClick", function()
        local name = BW:GetActiveProfileName()
        showConfirmPopup(format(L["Reset profile '%s' to defaults?"], name), function()
            BW:ResetProfile(name)
            if BW.RefreshAll then BW:RefreshAll() end
            if BW.ApplyFonts then BW:ApplyFonts() end
            if panel and panel.refreshAll then panel.refreshAll() end
        end)
    end)

    local btnDelete = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnDelete:SetSize(110, 22)
    btnDelete:SetPoint("LEFT", btnReset, "RIGHT", 6, 0)
    btnDelete:SetText(L["Delete"])
    addTooltip(btnDelete, L["Delete the active profile (cannot delete Default)."])
    btnDelete:SetScript("OnClick", function()
        local name = BW:GetActiveProfileName()
        if name == "Default" then
            print("|cffeda55fBossWatch:|r " .. L["cannot delete Default"])
            return
        end
        showConfirmPopup(format(L["Delete profile '%s'?"], name), function()
            BW:DeleteProfile(name)
            profileDropdownRefresh()
            if BW.RefreshAll then BW:RefreshAll() end
            if BW.ApplyFonts then BW:ApplyFonts() end
            if panel and panel.refreshAll then panel.refreshAll() end
        end)
    end)

    y = y - 36

    -- Export
    local exportLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    exportLabel:SetPoint("TOPLEFT", 14, y)
    exportLabel:SetText(L["Export"])

    y = y - 18

    local exportScroll = CreateFrame("ScrollFrame", nil, page, "InputScrollFrameTemplate")
    exportScroll:SetPoint("TOPLEFT", 14, y)
    exportScroll:SetSize(520, 80)
    local exportEdit = exportScroll.EditBox
    exportEdit:SetMaxLetters(0)
    exportEdit:SetFontObject("GameFontHighlightSmall")
    exportEdit:SetWidth(498)
    exportEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    addTooltip(exportEdit, L["Export string for the active profile. Click Select All then Ctrl+C to copy."])

    local function refreshExport()
        local s = BW:ExportProfile()
        exportEdit:SetText(s or "")
    end
    refreshExport()

    local btnRefreshExport = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnRefreshExport:SetSize(130, 22)
    btnRefreshExport:SetPoint("TOPLEFT", exportScroll, "BOTTOMLEFT", 0, -4)
    btnRefreshExport:SetText(L["Refresh export"])
    btnRefreshExport:SetScript("OnClick", refreshExport)
    addTooltip(btnRefreshExport, L["Re-generate the export string from the current profile settings."])

    local btnSelectAll = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnSelectAll:SetSize(130, 22)
    btnSelectAll:SetPoint("LEFT", btnRefreshExport, "RIGHT", 6, 0)
    btnSelectAll:SetText(L["Select all"])
    btnSelectAll:SetScript("OnClick", function()
        exportEdit:SetFocus(); exportEdit:HighlightText()
    end)
    addTooltip(btnSelectAll, L["Highlight the export string so you can Ctrl+C copy it."])

    y = y - 116

    -- Import
    local importLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importLabel:SetPoint("TOPLEFT", 14, y)
    importLabel:SetText(L["Import"])

    y = y - 18

    local importScroll = CreateFrame("ScrollFrame", nil, page, "InputScrollFrameTemplate")
    importScroll:SetPoint("TOPLEFT", 14, y)
    importScroll:SetSize(520, 80)
    local importEdit = importScroll.EditBox
    importEdit:SetMaxLetters(0)
    importEdit:SetFontObject("GameFontHighlightSmall")
    importEdit:SetWidth(498)
    importEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    addTooltip(importEdit, L["Paste a profile export string here, then click Import to create a new profile."])

    local btnImport = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnImport:SetSize(200, 22)
    btnImport:SetPoint("TOPLEFT", importScroll, "BOTTOMLEFT", 0, -4)
    btnImport:SetText(L["Import as new profile..."])
    addTooltip(btnImport, L["Paste a profile export string above and click here to import it as a new profile."])
    btnImport:SetScript("OnClick", function()
        local text = importEdit:GetText() or ""
        if text:gsub("%s", "") == "" then
            print("|cffeda55fBossWatch:|r " .. L["import box is empty"])
            return
        end
        showProfilePopup(L["Name for the imported profile:"], "", function(name)
            name = (name or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if name == "" then return end

            local function doImport(overwrite)
                local ok, err = BW:ImportProfile(text, name, overwrite)
                if ok then
                    BW:SetActiveProfile(name)
                    profileDropdownRefresh()
                    if panel and panel.refreshAll then panel.refreshAll() end
                    print("|cffeda55fBossWatch:|r " .. format(L["profile '%s' imported"], name))
                else
                    print("|cffeda55fBossWatch:|r " .. L["import failed:"] .. " " .. tostring(err))
                end
            end

            -- First try without overwrite; if name exists, prompt to overwrite.
            local ok, err = BW:ImportProfile(text, name, false)
            if ok then
                BW:SetActiveProfile(name)
                profileDropdownRefresh()
                if panel and panel.refreshAll then panel.refreshAll() end
                print("|cffeda55fBossWatch:|r " .. format(L["profile '%s' imported"], name))
            elseif err == "profile already exists" then
                showConfirmPopup(format(L["Overwrite existing profile '%s'?"], name),
                    function() doImport(true) end)
            else
                print("|cffeda55fBossWatch:|r " .. L["import failed:"] .. " " .. tostring(err))
            end
        end)
    end)
end

local function buildAboutPage(page)
    _currentSection = nil  -- this page has no makeSection — widgets shouldn't register
    local version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
    local author  = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Author")  or "Timikana"

    -- Logo (top left)
    local logo = page:CreateTexture(nil, "ARTWORK")
    logo:SetSize(140, 140)
    logo:SetPoint("TOPLEFT", page, "TOPLEFT", 14, -14)
    logo:SetTexture("Interface\\AddOns\\BossWatch\\Media\\logo.png")

    -- Right column anchored to logo
    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 16, -4)
    title:SetText("|cffeda55fBossWatch|r  v" .. version)

    local sub = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    sub:SetWidth(360); sub:SetJustifyH("LEFT")
    sub:SetText(L["Custom boss target frames for WoW Retail / Midnight 12.0."])

    local byLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    byLabel:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)
    byLabel:SetText(L["Author:"] .. " |cffffffff" .. author .. "|r")

    -- URL helper: a labelled EditBox (read-only-ish, click to select & copy)
    local function urlField(yOff, label, url)
        local lab = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lab:SetPoint("TOPLEFT", 14, yOff)
        lab:SetText(label)

        local eb = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
        eb:SetSize(440, 22)
        eb:SetPoint("TOPLEFT", lab, "BOTTOMLEFT", 6, -4)
        eb:SetAutoFocus(false)
        eb:SetFontObject("GameFontHighlightSmall")
        eb:SetText(url)
        eb:SetCursorPosition(0)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)
        eb:SetScript("OnMouseDown", function(self) self:HighlightText(); self:SetFocus() end)
        addTooltip(eb, L["Click to select, then Ctrl+C to copy."])
        return eb
    end

    -- URL fields go BELOW the logo (logo ends at y=-154 with 14px margin + 140 height)
    urlField(-170, "|cffffffff" .. L["GitHub repository:"]   .. "|r", "https://github.com/Timikana/BossWatch")
    urlField(-220, "|cffffffff" .. L["Report an issue:"]     .. "|r", "https://github.com/Timikana/BossWatch/issues")
    urlField(-270, "|cffeda14a"  .. (L["CurseForge:"] or "CurseForge:") .. "|r", "https://www.curseforge.com/wow/addons/bosswatch")
    urlField(-320, "|cffb371ff"  .. (L["Wago:"]       or "Wago:")       .. "|r", "https://addons.wago.io/addons/bosswatch")
    urlField(-370, "|cff5865f2"  .. (L["Discord (support / bugs / suggestions):"] or "Discord (support / bugs / suggestions):") .. "|r", "https://discord.gg/uFmxwexQ4P")

    -- Panel opacity (account-wide, not per-profile)
    local alphaSlider = CreateFrame("Frame", nil, page, "MinimalSliderWithSteppersTemplate")
    alphaSlider:SetWidth(220)
    alphaSlider:SetPoint("TOPLEFT", page, "TOPLEFT", 14, -440)
    local function fmtPct(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end
    local alphaFormatters = {
        [MinimalSliderWithSteppersMixin.Label.Min] = function() return "20%" end,
        [MinimalSliderWithSteppersMixin.Label.Max] = function() return "100%" end,
        [MinimalSliderWithSteppersMixin.Label.Top] = function(v)
            return L["Panel opacity"] .. ": " .. fmtPct(v)
        end,
    }
    BossWatchDB = BossWatchDB or {}
    if BossWatchDB.panelAlpha == nil then BossWatchDB.panelAlpha = 0.8 end
    alphaSlider:Init(BossWatchDB.panelAlpha, 0.2, 1.0, 16, alphaFormatters)
    local alphaEvent = (MinimalSliderWithSteppersMixin.Event
        and MinimalSliderWithSteppersMixin.Event.OnValueChanged) or "OnValueChanged"
    alphaSlider:RegisterCallback(alphaEvent, function(_, v)
        v = math.floor(v * 20 + 0.5) / 20
        BossWatchDB.panelAlpha = v
        if panel then panel:SetAlpha(v) end
    end, alphaSlider)
    addTooltip(alphaSlider, L["Opacity of this options window. Saved account-wide."])

    -- Reset window size/position button (account-wide)
    local btnResetWin = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnResetWin:SetSize(160, 22)
    btnResetWin:SetPoint("TOPLEFT", page, "TOPLEFT", 260, -440)
    btnResetWin:SetText(L["Reset window size"])
    btnResetWin:SetScript("OnClick", function()
        BossWatchDB.panelW = nil
        BossWatchDB.panelH = nil
        BossWatchDB.panelPoint = nil
        if panel then
            panel:SetSize(720, 620)
            panel:ClearAllPoints()
            panel:SetPoint("CENTER")
        end
    end)
    addTooltip(btnResetWin, L["Reset the options window to its default size and position."])

    local cmdHeader = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cmdHeader:SetPoint("TOPLEFT", 14, -500)
    cmdHeader:SetText(L["Slash commands"])

    local cmds = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cmds:SetPoint("TOPLEFT", cmdHeader, "BOTTOMLEFT", 0, -6)
    cmds:SetWidth(680); cmds:SetJustifyH("LEFT"); cmds:SetSpacing(3)
    cmds:SetText(
        "|cffffff00/bw|r — " .. L["open options"] .. "\n" ..
        "|cffffff00/bw config|r |cff888888(" .. L["alias"] .. ")|r — " .. L["open options"] .. "\n" ..
        "|cffffff00/bw options|r |cff888888(" .. L["alias"] .. ")|r — " .. L["open options"] .. "\n" ..
        "|cffffff00/bw mover|r — " .. L["toggle mover"] .. "\n" ..
        "|cffffff00/bw test N|r — " .. L["simulate N bosses (0-5)"] .. "\n" ..
        "|cffffff00/bw test 0|r — " .. L["stop the simulation"] .. "\n" ..
        "|cffffff00/bw reset|r — " .. L["reset all settings + reload"]
    )

    local hint = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 14, 12)
    hint:SetText(L["Click a URL to select it, then Ctrl+C to copy."])
end

-- ============================================================
-- BUILD
-- ============================================================

local function build()
    -- Modern Blizzard 11.0 portrait frame (used by Item Upgrades, Adventure Guide, etc.)
    panel = CreateFrame("Frame", "BossWatchOptions", UIParent, "PortraitFrameTemplate")
    BossWatchDB = BossWatchDB or {}
    local startW = math.max(720, BossWatchDB.panelW or 720)
    local startH = math.max(500, BossWatchDB.panelH or 620)
    panel:SetSize(startW, startH)
    if BossWatchDB.panelPoint then
        local p = BossWatchDB.panelPoint
        panel:ClearAllPoints()
        panel:SetPoint(p.point or "CENTER", UIParent, p.relPoint or "CENTER", p.x or 0, p.y or 0)
    else
        panel:SetPoint("CENTER")
    end
    panel:SetMovable(true); panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint(1)
        BossWatchDB.panelPoint = { point = point, relPoint = relPoint,
                                   x = math.floor((x or 0) + 0.5),
                                   y = math.floor((y or 0) + 0.5) }
    end)
    panel:SetFrameStrata("HIGH")
    panel:Hide()
    panel:SetClampedToScreen(true)
    panel:SetResizable(true)
    if panel.SetResizeBounds then
        panel:SetResizeBounds(720, 500, 1400, 1100)
    end

    -- Resize grip (bottom-right)
    local grip = CreateFrame("Button", nil, panel)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -4, 4)
    grip:SetFrameLevel(panel:GetFrameLevel() + 10)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then panel:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnMouseUp", function()
        panel:StopMovingOrSizing()
        BossWatchDB.panelW = math.floor(panel:GetWidth() + 0.5)
        BossWatchDB.panelH = math.floor(panel:GetHeight() + 0.5)
    end)
    addTooltip(grip, L["Drag to resize the options window. Saved account-wide."])
    -- Close on Escape (Blizzard's UI special-frames list)
    tinsert(UISpecialFrames, "BossWatchOptions")

    if panel.SetTitle then panel:SetTitle(L["BossWatch — Options"]) end
    -- Set the portrait by direct texture access (more reliable than SetPortraitToAsset
    -- across template variants — that API sometimes fails silently and shows the
    -- green default placeholder).
    local portraitTex
    if panel.PortraitContainer and panel.PortraitContainer.portrait then
        portraitTex = panel.PortraitContainer.portrait
    elseif panel.GetPortrait then
        portraitTex = panel:GetPortrait()
    end
    if portraitTex then
        portraitTex:SetTexture("Interface\\AddOns\\BossWatch\\Media\\logo.png")
        portraitTex:SetTexCoord(0, 1, 0, 1)
    elseif panel.SetPortraitToAsset then
        panel:SetPortraitToAsset("Interface\\AddOns\\BossWatch\\Media\\logo.png")
    end

    local pageHolder = CreateFrame("Frame", nil, panel)
    pageHolder:SetPoint("TOPLEFT", 8, -60)
    pageHolder:SetPoint("BOTTOMRIGHT", -8, 8)

    -- Panel opacity (account-wide preference) — slider lives in Disposition > General
    BossWatchDB = BossWatchDB or {}
    if BossWatchDB.panelAlpha == nil then BossWatchDB.panelAlpha = 0.8 end
    panel:SetAlpha(BossWatchDB.panelAlpha)

    local pages = {}
    -- Each "page" is actually a ScrollFrame so long content scrolls cleanly.
    -- Build functions receive the inner content frame as their parent.
    local function newPage(name)
        local sf = CreateFrame("ScrollFrame", "BWScroll_"..name, pageHolder, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", pageHolder, "TOPLEFT", 0, 0)
        sf:SetPoint("BOTTOMRIGHT", pageHolder, "BOTTOMRIGHT", -24, 0)
        sf:Hide()

        local content = CreateFrame("Frame", nil, sf)
        content:SetSize(sf:GetWidth() > 0 and sf:GetWidth() or 680, 900)
        sf:SetScrollChild(content)
        sf.content = content
        -- Content width must follow scroll viewport so section dividers
        -- and the scrollbar don't clip when the panel is resized.
        sf:SetScript("OnSizeChanged", function(self, w, _)
            if w and w > 0 and self.content then self.content:SetWidth(w) end
        end)
        return sf
    end

    -- Measure children + regions of content, set content height, hide scrollbar if content fits viewport
    local function autoFitPage(sf)
        C_Timer.After(0, function()
            local content = sf.content
            if not content or not content:GetTop() then return end
            local top = content:GetTop()
            local lowest = top
            for _, child in ipairs({content:GetChildren()}) do
                if child:IsShown() then
                    local b = child:GetBottom()
                    if b and b < lowest then lowest = b end
                end
            end
            for _, region in ipairs({content:GetRegions()}) do
                if region:IsShown() then
                    local b = region:GetBottom()
                    if b and b < lowest then lowest = b end
                end
            end
            local used = math.max(50, top - lowest + 16)
            local viewportH = sf:GetHeight()
            content:SetHeight(math.max(used, viewportH))
            local sb = sf.ScrollBar or _G[sf:GetName() .. "ScrollBar"]
            if sb then sb:SetShown(used > viewportH + 1) end
        end)
    end

    pages.layout   = newPage("layout");   buildLayoutPage(pages.layout.content);     autoFitPage(pages.layout)
    pages.bars     = newPage("bars");     buildBarsPage(pages.bars.content);         autoFitPage(pages.bars)
    pages.cast     = newPage("cast");     buildCastPage(pages.cast.content);         autoFitPage(pages.cast)
    pages.text     = newPage("text");     buildTextPage(pages.text.content);         autoFitPage(pages.text)
    pages.raid     = newPage("raid");     buildRaidMarkerPage(pages.raid.content);   autoFitPage(pages.raid)
    pages.auras    = newPage("auras");    buildAurasPage(pages.auras.content);       autoFitPage(pages.auras)
    pages.profiles = newPage("profiles"); buildProfilesPage(pages.profiles.content); autoFitPage(pages.profiles)
    pages.about    = newPage("about");    buildAboutPage(pages.about.content);       autoFitPage(pages.about)

    local tabs = {
        { id = "layout",   label = L["Layout"] },
        { id = "bars",     label = L["Bars"] },
        { id = "cast",     label = L["Cast Bar"] },
        { id = "text",     label = L["Text"] },
        { id = "raid",     label = L["Raid Marker"] },
        { id = "auras",    label = L["Auras"] },
        { id = "profiles", label = L["Profiles"] },
        { id = "about",    label = L["About"] },
    }
    local tabBtns = {}
    local function selectTab(id)
        for _, p in pairs(pages) do p:Hide() end
        if pages[id] then pages[id]:Show() end
        for _, t in ipairs(tabBtns) do
            if t.id == id then
                if PanelTemplates_SelectTab then PanelTemplates_SelectTab(t) end
            else
                if PanelTemplates_DeselectTab then PanelTemplates_DeselectTab(t) end
            end
        end
    end

    for i, t in ipairs(tabs) do
        local b = makeTab(panel, t.id, t.label, i, tabBtns[i - 1])
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

function BW:RegisterBlizzardSettings()
    if BW._settingsCategoryID or not Settings or not Settings.RegisterCanvasLayoutCategory then
        return
    end
    local host = CreateFrame("Frame")
    host.name = "BossWatch"

    local title = host:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("BossWatch")

    local version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
    local sub = host:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    sub:SetWidth(540); sub:SetJustifyH("LEFT")
    sub:SetText(format(L["Custom boss target frames — v%s\nClick the button below to open the BossWatch configuration panel."], version))

    local btn = CreateFrame("Button", nil, host, "UIPanelButtonTemplate")
    btn:SetSize(220, 26)
    btn:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)
    btn:SetText(L["Open BossWatch options"])
    btn:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
        if not panel or not panel:IsShown() then BW:ToggleOptions() end
    end)
    addTooltip(btn, L["Open the floating BossWatch options panel."])

    local hint = host:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -10)
    hint:SetText(L["You can also use the slash command: /bw"])

    local category = Settings.RegisterCanvasLayoutCategory(host, "BossWatch")
    category.ID = "BossWatch"
    Settings.RegisterAddOnCategory(category)
    BW._settingsCategoryID = category:GetID()
end
