-- Options/Widgets.lua — widget factories (addTooltip, markAsNew, makeSlider,
-- makeCheck, makeDropdown, makeMediaDropdown, makeColorPicker) + ANCHOR9.
--
-- This file is loaded BEFORE Options/Panel.lua. The factories register
-- themselves onto BossW.Options.<name>. They reference Panel.lua's
-- _registerInSection via O._registerInSection at CALL time (resolved when
-- the options panel is opened, after every Options/*.lua has loaded).
local addonName, BossW = ...
local L = BossW.L

BossW.Options = BossW.Options or {}
BossW.Options.Pages = BossW.Options.Pages or {}
local O = BossW.Options

local CreateFrame = CreateFrame
local pairs, ipairs, tostring = pairs, ipairs, tostring
local format = string.format
local pcall = pcall

-- Shared "redraw all" entry point — equivalent of Panel.lua's old local
-- refresh helper. Inlined here so we don't need a cross-file reference.
local function refresh()
    if BossW.RefreshAll then BossW:RefreshAll() end
end

-- ============================================================
-- addTooltip
-- ============================================================
O.addTooltip = function(widget, text)
    if not widget or not text or text == "" then return widget end
    -- Index for the search bar (label + tooltip body, lower-cased once at build time)
    widget._searchText = ((widget._searchText or "") .. " " .. text):lower()
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

-- ============================================================
-- markAsNew — "NEW" badge that disappears on first hover/click
-- ============================================================
O.markAsNew = function(widget, dbKey)
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
-- makeSlider
-- ============================================================
O.makeSlider = function(parent, label, key, minV, maxV, step, x, y, width)
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
        local v = BossW:GetDB()[key]
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
        BossW:GetDB()[key] = value
        refresh()
    end, sl)

    sl.refresh = function() sl:Init(readDB(), minV, maxV, numSteps, formatters) end
    sl._searchText = label or ""
    sl._searchGroup = { sl }
    if O._registerInSection then O._registerInSection(sl, key) end
    return sl
end

-- ============================================================
-- makeCheck
-- ============================================================
O.makeCheck = function(parent, label, key, x, y)
    local cb = CreateFrame("CheckButton", "BWOpt_"..key, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetSize(24, 24)
    cb.Text:SetFontObject("GameFontHighlight")
    cb.Text:SetText(label)
    cb.dbKey = key
    cb:SetScript("OnClick", function(self)
        BossW:GetDB()[key] = self:GetChecked() and true or false
        refresh()
    end)
    cb._searchText = label or ""
    cb._searchGroup = { cb }
    if O._registerInSection then O._registerInSection(cb, key) end
    return cb
end

-- ============================================================
-- makeDropdown
-- ============================================================
O.makeDropdown = function(parent, label, key, options, x, y, width)
    -- Modern 11.0 dropdown (same template used by native Settings panels).
    -- The dropdown body is the anchor parent (so col2 auto-flow works) and
    -- the label sits ABOVE it — visual position identical to the old layout
    -- where the label was the parent.
    local dd = CreateFrame("DropdownButton", "BWOpt_DD_"..key, parent, "WowStyle1DropdownTemplate")
    dd:SetWidth(width or 160)
    dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 16)
    dd.dbKey = key
    dd._options = options

    local labelFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelFS:SetPoint("BOTTOMLEFT", dd, "TOPLEFT", 0, 2)
    labelFS:SetText(label)

    dd:SetupMenu(function(_, rootDescription)
        for _, opt in ipairs(options) do
            rootDescription:CreateRadio(opt.text,
                function() return BossW:GetDB()[key] == opt.value end,
                function()
                    BossW:GetDB()[key] = opt.value
                    refresh()
                end)
        end
    end)
    dd.refresh = function() dd:GenerateMenu() end
    dd._labelFS = labelFS
    dd._searchText = label or ""
    dd._searchGroup = { dd, labelFS }  -- dd is the leader (auto-flow target)
    if O._registerInSection then
        O._registerInSection(dd, key)
        O._registerInSection(labelFS)
    end
    return dd
end

-- ============================================================
-- makeMediaDropdown — LSM picker with scrollable popup + preview
-- ============================================================
local POPUP_ITEM_H = 22
local POPUP_VISIBLE = 12

O.makeMediaDropdown = function(parent, label, key, mediaType, x, y, width, tint)
    width = width or 180
    -- tint = {r,g,b} optional preview color. nil = no tint (show texture as-is).
    local TR, TG, TB = 1, 1, 1
    if tint then TR, TG, TB = tint[1] or 1, tint[2] or 1, tint[3] or 1 end

    -- Anchor button (acts as the dropdown header) — modern dark style.
    -- btn is the anchor parent so col2 auto-flow works; labelFS sits above it.
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 24)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 18)

    local labelFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelFS:SetPoint("BOTTOMLEFT", btn, "TOPLEFT", 0, 4)
    labelFS:SetText(label)
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
            pcall(previewText.SetFont, previewText, BossW:ResolveFont(name), 13, "")
        else
            previewTex:SetTexture(BossW:ResolveTexture(name))
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
                pcall(it.fs.SetFont, it.fs, BossW:ResolveFont(name), 13, "")
                it.fs:SetText(name)
            else
                it.bar:SetTexture(BossW:ResolveTexture(name))
                it.bar:SetVertexColor(TR, TG, TB, 1)
                it.nameFS:SetText(name)
            end
            it:SetScript("OnClick", function()
                BossW:GetDB()[key] = name
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
        local cur = BossW:GetDB()[key] or "Blizzard"
        btnText:SetText(cur)
        applyPreview(cur)
    end
    btn.refresh()
    -- Register all the sibling regions of the media dropdown so that collapsing
    -- the section hides the label and the preview as well, not just the button.
    btn._searchText = label or ""
    btn._searchGroup = { btn, labelFS, previewBg, previewBorder, (previewTex or previewText) }
    if O._registerInSection then
        O._registerInSection(btn, key)
        O._registerInSection(labelFS)
        O._registerInSection(previewBg)
        O._registerInSection(previewBorder)
        if previewTex then O._registerInSection(previewTex) end
        if previewText then O._registerInSection(previewText) end
    end
    return btn
end

-- ============================================================
-- makeColorPicker
-- ============================================================
O.makeColorPicker = function(parent, label, dbKey, x, y)
    local lab
    -- Modern compact swatch button: gold thin border + inner color swatch.
    -- btn is the anchor parent; the optional label sits above it. This way
    -- col2 colorpickers participate in auto-flow.
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(28, 22)
    local hasLabel = label and label ~= ""
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, hasLabel and (y - 16) or y)
    btn:RegisterForClicks("AnyUp")

    if hasLabel then
        lab = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lab:SetPoint("BOTTOMLEFT", btn, "TOPLEFT", 0, 2)
        lab:SetText(label)
    end

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
        return BossW:GetDB()[dbKey] or { r = 1, g = 1, b = 1, a = 1 }
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
            BossW:GetDB()[dbKey] = { r = r, g = g, b = b, a = a or 1 }
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
    btn._searchText = label or ""
    btn._searchGroup = lab and { btn, lab } or { btn }
    if O._registerInSection then
        O._registerInSection(btn, dbKey)
        if lab then O._registerInSection(lab) end
    end
    return btn
end

-- ============================================================
-- ANCHOR9 — list of {text=L["..."], value="ANCHOR_NAME"} for 9-point pickers
-- ============================================================
O.ANCHOR9 = function()
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
