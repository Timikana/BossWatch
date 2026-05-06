local addonName, BW = ...
local L = BW.L

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

local POPUP_ITEM_H = 22
local POPUP_VISIBLE = 12

local function makeMediaDropdown(parent, label, key, mediaType, x, y, width)
    width = width or 180

    local labelFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelFS:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    labelFS:SetText(label)

    -- Anchor button (acts as the dropdown header)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 22)
    btn:SetPoint("TOPLEFT", labelFS, "BOTTOMLEFT", 0, -4)
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.08, 0.08, 0.10, 1)
    btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
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
            previewTex:SetVertexColor(0.9, 0.2, 0.2, 1)
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
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    popup:SetBackdropColor(0.04, 0.04, 0.06, 0.97)
    popup:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
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
                it.bar:SetVertexColor(0.9, 0.2, 0.2, 1)
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
    return btn
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

local function makeTab(parent, id, label, idx)
    local tab = CreateFrame("Button", "BWTab"..id, parent, "BackdropTemplate")
    tab:SetSize(72, 22)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", 8 + (idx - 1) * 76, -28)
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
    btnMover:SetText(L["Unlock / Lock Mover"])
    btnMover:SetScript("OnClick", function() BW:ToggleMover() end)

    local label = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", 184, y - 4)
    label:SetText(L["Test:"])

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
            if b._count == n then
                b:LockHighlight()
            else
                b:UnlockHighlight()
            end
        end
    end

    local xs = 220
    for _, count in ipairs({ 0, 1, 2, 3, 4, 5 }) do
        local b = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
        b:SetSize(36, 22)
        b:SetPoint("TOPLEFT", xs, y)
        b:SetText(count == 0 and L["Off"] or tostring(count))
        b._count = count
        b:SetScript("OnClick", function()
            BW:SetTestMode(count)
            refreshTestBtns()
        end)
        testBtns[#testBtns + 1] = b
        xs = xs + 38
    end
    refreshTestBtns()

    y = y - 30
    makeCheck(page, L["Enable"], "enabled", 14, y); makeCheck(page, L["Hide Blizzard"], "hideBlizzard", 184, y)
    y = y - 26
    makeDropdown(page, L["Anchor"], "anchor", ANCHOR9(), 14, y); makeDropdown(page, L["Grow Direction"], "growDirection", {
        { text = L["Down"], value = "DOWN" }, { text = L["Up"], value = "UP" },
    }, 184, y)
    y = y - 50
    makeSlider(page, L["Offset X"], "anchorX", -1500, 1500, 1, 14, y)
    makeSlider(page, L["Offset Y"], "anchorY", -1500, 1500, 1, 260, y)
    y = y - 50
    makeSlider(page, L["Width"],   "frameWidth",   100, 400, 1, 14, y)
    makeSlider(page, L["Height"],  "frameHeight",   20, 100, 1, 260, y)
    y = y - 50
    makeSlider(page, L["Spacing"], "frameSpacing",  0,  40, 1,  14, y)
    makeSlider(page, L["Scale"],   "frameScale",  0.5, 2.0, 0.05, 260, y)
    y = y - 50
    makeDropdown(page, L["Portrait Position"], "portraitPosition", {
        { text = L["Left"], value = "LEFT" },
        { text = L["Right"], value = "RIGHT" },
        { text = L["Hidden"], value = "HIDDEN" },
    }, 14, y)
    makeSlider(page, L["Portrait Size"], "portraitSize", 20, 80, 1, 260, y)
end

local function buildBarsPage(page)
    local y = -10
    makeMediaDropdown(page, L["Health Texture"], "healthTexture", "statusbar", 14, y, 180)
    y = y - 50
    makeMediaDropdown(page, L["Power Texture"], "powerTexture", "statusbar", 14, y, 180)
    y = y - 50
    makeCheck(page, L["Show Power Bar"], "showPowerBar", 14, y)
    makeSlider(page, L["Power Bar Height"], "powerBarHeight", 2, 20, 1, 184, y)
    y = y - 50
    makeDropdown(page, L["Health Color"], "healthColorMode", {
        { text = L["Reaction (Blizzard)"], value = "REACTION" },
        { text = L["Class fallback"],      value = "CLASS_FALLBACK" },
        { text = L["Custom static"],       value = "STATIC" },
    }, 14, y, 180)
    y = y - 50
    makeSlider(page, L["HP background alpha"], "healthBackgroundAlpha", 0, 1, 0.05, 14, y)
    makeSlider(page, L["Power background alpha"], "powerBackgroundAlpha", 0, 1, 0.05, 260, y)
end

local function buildCastPage(page)
    local y = -10
    makeMediaDropdown(page, L["Cast Bar Texture"], "castTexture", "statusbar", 14, y, 180)
    y = y - 50
    makeCheck(page, L["Show Cast Bar"], "showCastBar", 14, y)
    makeCheck(page, L["Detached"], "castBarDetached", 184, y)
    y = y - 26
    makeSlider(page, L["Cast Bar Height"], "castBarHeight", 8, 40, 1, 14, y, 160)
    makeDropdown(page, L["Icon Position"], "castBarIconPosition", {
        { text = L["Left"], value = "LEFT" }, { text = L["Right"], value = "RIGHT" },
    }, 270, y)
    y = y - 50
    makeSlider(page, L["Cast bg alpha"], "castBackgroundAlpha", 0, 1, 0.05, 14, y)
    y = y - 50
    makeDropdown(page, L["Detached Anchor"], "castBarDetachedAnchor", ANCHOR9(), 14, y)
    makeSlider(page, L["Detached Width (0=auto)"], "castBarDetachedWidth", 0, 400, 1, 260, y)
    y = y - 50
    makeSlider(page, L["Detached Offset X"], "castBarDetachedX", -200, 200, 1, 14, y)
    makeSlider(page, L["Detached Offset Y"], "castBarDetachedY", -200, 200, 1, 260, y)
end

local function buildTextPage(page)
    local y = -10
    makeCheck(page, L["Show Name"], "showName", 14, y)
    makeDropdown(page, L["Name Position"], "nameAnchor", ANCHOR9(), 184, y)
    y = y - 50
    makeSlider(page, L["Name Offset X"], "nameX", -80, 80, 1, 14, y)
    makeSlider(page, L["Name Offset Y"], "nameY", -80, 80, 1, 260, y)
    y = y - 50
    makeSlider(page, L["Name max length (0=off)"], "nameMaxLength", 0, 40, 1, 14, y, 250)
    y = y - 40

    makeCheck(page, L["Show Health Text"], "showHealthText", 14, y)
    makeDropdown(page, L["HP text position"], "healthTextAnchor", ANCHOR9(), 184, y)
    y = y - 50
    makeSlider(page, L["HP text Offset X"], "healthTextX", -80, 80, 1, 14, y)
    makeSlider(page, L["HP text Offset Y"], "healthTextY", -80, 80, 1, 260, y)
    y = y - 50
    makeDropdown(page, L["HP format"], "healthTextFormat", {
        { text = L["Percent (50%)"],     value = "PERCENT" },
        { text = L["Current (50M)"],      value = "CURRENT" },
        { text = L["Current + Percent"],  value = "CURRENT_PERCENT" },
        { text = L["Current / Max"],      value = "CURRENT_MAX" },
    }, 14, y, 200)

    y = y - 50
    makeCheck(page, L["Show Power Text"], "showPowerText", 14, y)
    makeDropdown(page, L["Power format"], "powerTextFormat", {
        { text = L["Percent (50%)"],     value = "PERCENT" },
        { text = L["Current (50M)"],      value = "CURRENT" },
        { text = L["Current + Percent"],  value = "CURRENT_PERCENT" },
        { text = L["Current / Max"],      value = "CURRENT_MAX" },
    }, 184, y, 200)

    y = y - 60
    local fontHeader = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fontHeader:SetPoint("TOPLEFT", 14, y)
    fontHeader:SetText(L["Font (applies to all text)"])
    y = y - 18
    makeMediaDropdown(page, L["Font"], "fontFace", "font", 14, y, 180)
    y = y - 50
    makeSlider(page, L["Font Size"], "fontSize", 8, 24, 1, 14, y)
    makeDropdown(page, L["Outline"], "fontOutline", {
        { text = L["None"],          value = "NONE" },
        { text = L["Outline"],       value = "OUTLINE" },
        { text = L["Thick Outline"], value = "THICKOUTLINE" },
    }, 260, y)
end

local function buildRaidMarkerPage(page)
    local y = -10
    makeCheck(page, L["Show Raid Target Icon"], "showRaidTargetIcon", 14, y)
    y = y - 30
    local note = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 14, y)
    note:SetWidth(520); note:SetJustifyH("LEFT")
    note:SetText(L["Position the raid target icon (skull, cross, star...) on each boss frame."])
    y = y - 30
    makeDropdown(page, L["Anchor"], "raidTargetAnchor", ANCHOR9(), 14, y)
    y = y - 50
    makeSlider(page, L["Offset X"], "raidTargetX", -200, 200, 1, 14, y)
    makeSlider(page, L["Offset Y"], "raidTargetY", -200, 200, 1, 260, y)
    y = y - 50
    makeSlider(page, L["Size"], "raidTargetSize", 10, 64, 1, 14, y)
    makeSlider(page, L["Alpha"], "raidTargetAlpha", 0, 1, 0.05, 260, y)
end

local function buildAurasPage(page)
    local y = -10
    makeCheck(page, L["Show Auras"], "showAuras", 14, y)
    makeDropdown(page, L["Filter"], "aurasFilter", {
        { text = L["Debuffs (HARMFUL)"], value = "HARMFUL" },
        { text = L["Buffs (HELPFUL)"],   value = "HELPFUL" },
    }, 184, y)
    y = y - 50
    makeDropdown(page, L["Source"], "aurasSource", {
        { text = L["All (Blizzard-like)"], value = "ALL" },
        { text = L["Only mine"],           value = "MINE" },
        { text = L["Hide mine"],           value = "NOT_MINE" },
        { text = L["Boss-cast only"],      value = "BOSS_ONLY" },
    }, 14, y, 180)
    y = y - 50
    makeSlider(page, L["Max Count"], "aurasMaxCount", 1, 8, 1, 14, y)
    makeSlider(page, L["Size"], "aurasSize", 12, 48, 1, 260, y)
    y = y - 50
    makeSlider(page, L["Spacing"], "aurasSpacing", 0, 10, 1, 14, y)
    y = y - 40
    makeCheck(page, L["Show Stacks"], "aurasShowStacks", 14, y)
    makeCheck(page, L["Show Timer"],  "aurasShowTimer",  184, y)
    y = y - 26
    makeDropdown(page, L["Anchor"], "aurasAnchor", ANCHOR9(), 14, y)
    makeDropdown(page, L["Grow X"], "aurasGrowX", {
        { text = L["Left"],  value = "LEFT" },
        { text = L["Right"], value = "RIGHT" },
    }, 260, y)
    y = y - 50
    makeSlider(page, L["Offset X"], "aurasX", -200, 200, 1, 14, y)
    makeSlider(page, L["Offset Y"], "aurasY", -200, 200, 1, 260, y)
    y = y - 50
    makeDropdown(page, L["Timer Placement"], "aurasTimerPlacement", {
        { text = L["Inside (centered)"], value = "INSIDE" },
        { text = L["Below icon"],        value = "BELOW" },
        { text = L["Above icon"],        value = "ABOVE" },
    }, 14, y)
end

local function buildAboutPage(page)
    local version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
    local author  = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Author")  or "Timikana"

    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -14)
    title:SetText("|cffeda55fBossWatch|r  v" .. version)

    local sub = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetWidth(520); sub:SetJustifyH("LEFT")
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
        return eb
    end

    urlField(-90,  L["GitHub repository:"],    "https://github.com/Timikana/BossWatch")
    urlField(-150, L["Report an issue:"],      "https://github.com/Timikana/BossWatch/issues")

    local cmdHeader = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cmdHeader:SetPoint("TOPLEFT", 14, -210)
    cmdHeader:SetText(L["Slash commands"])

    local cmds = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cmds:SetPoint("TOPLEFT", cmdHeader, "BOTTOMLEFT", 0, -6)
    cmds:SetWidth(520); cmds:SetJustifyH("LEFT"); cmds:SetSpacing(3)
    cmds:SetText(
        "|cffffff00/bw|r — " .. L["open options"] .. "\n" ..
        "|cffffff00/bw mover|r — " .. L["toggle mover"] .. "\n" ..
        "|cffffff00/bw test N|r — " .. L["simulate N bosses (0-5)"] .. "\n" ..
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
    panel = CreateFrame("Frame", "BossWatchOptions", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(560, 540)
    panel:SetPoint("CENTER")
    panel:SetMovable(true); panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetFrameStrata("HIGH")
    panel:Hide()
    panel.TitleText:SetText(L["BossWatch — Options"])

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
    pages.raid   = newPage(); buildRaidMarkerPage(pages.raid)
    pages.auras  = newPage(); buildAurasPage(pages.auras)
    pages.about  = newPage(); buildAboutPage(pages.about)

    local tabs = {
        { id = "layout", label = L["Layout"] },
        { id = "bars",   label = L["Bars"] },
        { id = "cast",   label = L["Cast Bar"] },
        { id = "text",   label = L["Text"] },
        { id = "raid",   label = L["Raid Marker"] },
        { id = "auras",  label = L["Auras"] },
        { id = "about",  label = L["About"] },
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

    local hint = host:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -10)
    hint:SetText(L["You can also use the slash command: /bw"])

    local category = Settings.RegisterCanvasLayoutCategory(host, "BossWatch")
    category.ID = "BossWatch"
    Settings.RegisterAddOnCategory(category)
    BW._settingsCategoryID = category:GetID()
end
