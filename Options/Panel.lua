local addonName, BossW = ...
local L = BossW.L

local CreateFrame = CreateFrame
local pairs, ipairs = pairs, ipairs

-- Shared namespace for external page files (Options/Pages/*.lua).
-- After this file loads, external files use `BossW.Options.makeCheck` etc.
-- and register their builders into `BossW.Options.Pages.<id>`.
BossW.Options = BossW.Options or {}
BossW.Options.Pages = BossW.Options.Pages or {}
local O = BossW.Options

local panel
local refresh = function() if BossW.RefreshAll then BossW:RefreshAll() end end

-- Widget factories live in Options/Widgets.lua (loaded BEFORE this file
-- by the TOC). We alias them locally so the harness/makeSection code
-- below reads cleanly without `O.` prefixes everywhere.
local addTooltip        = O.addTooltip
local markAsNew         = O.markAsNew
local makeSlider        = O.makeSlider
local makeCheck         = O.makeCheck
local makeDropdown      = O.makeDropdown
local makeMediaDropdown = O.makeMediaDropdown
local makeColorPicker   = O.makeColorPicker
local ANCHOR9           = O.ANCHOR9

-- Module-level pointer used by widget factories to auto-register with the
-- currently-being-built section. Each makeSection() updates this; each
-- makeXxx() factory pushes itself onto _currentSection.children/dbKeys.
local _currentSection = nil
-- Chain of last-built section per page so makeSection() anchors its container
-- under the previous section, which lets collapsing one section pull the rest
-- of the page up.
local _lastSectionOnPage = {}
local _allSectionsOnPage = {}  -- [page] = { section1, section2, ... } in order

local function _refreshHeightsForPage(parent)
    local list = _allSectionsOnPage[parent]
    if not list then return end
    for _, s in ipairs(list) do
        if not s._collapsed then s:UpdateNaturalHeight() end
    end
end

-- Tab badge wiring populated by build()
local _searchTabRefs = {}

-- Forward declaration: the actual search implementation lives inside build()
-- so it can close over `pages`, the results page, and `selectTab`. The search
-- EditBox calls _applySearch() which delegates here.
local _searchImpl = function() end
local function _applySearch(q) return _searchImpl(q) end

local function _captureAndReparent(widget, container, sectionOriginY)
    -- Reparent the widget to the section container so it inherits visibility
    -- (we still call Hide() on collapse for click-through reasons).
    -- Convert page-relative anchors to container-relative so when the container
    -- moves up after a previous section is collapsed, the widget moves with it.
    -- We also stash _homeContainer + _homeAnchors so the search results page
    -- can move the widget out and put it back later.
    if not widget or not widget.GetPoint or not widget.SetPoint or not widget.SetParent then return end
    local nPoints = widget.GetNumPoints and widget:GetNumPoints() or 0
    if nPoints == 0 then return end
    local pageRoot = container:GetParent()
    -- Capture all points first (SetParent + ClearAllPoints will drop them)
    local saved = {}
    for i = 1, nPoints do
        local p, relTo, relPoint, x, y = widget:GetPoint(i)
        saved[i] = { p = p, relTo = relTo, relPoint = relPoint, x = x or 0, y = y or 0 }
    end
    widget:SetParent(container)
    widget:ClearAllPoints()
    widget._homeContainer = container
    widget._homeAnchors = {}

    -- Auto-flow: widgets that were originally placed in the right column
    -- (x >= 240 in the 672-wide reference layout) get re-anchored to the
    -- container's TOPRIGHT instead of TOPLEFT, preserving their original
    -- right-edge offset. As the panel resizes wider, the right-column
    -- widgets slide along with the right edge instead of leaving dead space.
    local COL2_THRESHOLD = 240
    local REFERENCE_W    = 672

    for i, a in ipairs(saved) do
        local newY    = a.y
        local relTo   = a.relTo
        local newP    = a.p
        local newRP   = a.relPoint
        local newX    = a.x
        if a.relTo == pageRoot or a.relTo == nil then
            relTo = container
            newY  = a.y - sectionOriginY
            -- Convert col2 page-relative anchors to TOPRIGHT-relative.
            -- Skip FontStrings/Textures: their width is content-driven and
            -- changes the anchor point ambiguously, which breaks chained
            -- widgets (a dropdown body anchored to its label, etc.).
            local oType   = (widget.GetObjectType and widget:GetObjectType()) or ""
            local widgetW = (widget.GetWidth and widget:GetWidth()) or 0
            local isFrame = oType ~= "FontString" and oType ~= "Texture"
            if isFrame and a.x >= COL2_THRESHOLD and widgetW > 0 and a.p == "TOPLEFT" then
                local rightMargin = REFERENCE_W - (a.x + widgetW)
                if rightMargin < 4 then rightMargin = 4 end
                newP  = "TOPRIGHT"
                newRP = "TOPRIGHT"
                newX  = -rightMargin
            end
        end
        widget:SetPoint(newP, relTo, newRP, newX, newY)
        widget._homeAnchors[i] = { p = newP, relTo = relTo, relPoint = newRP, x = newX, y = newY }
    end
end

local function _registerInSection(widget, dbKey)
    if _currentSection and widget then
        _captureAndReparent(widget, _currentSection.container, _currentSection._originalY)
        widget._homeSection = _currentSection
        _currentSection.children[#_currentSection.children + 1] = widget
        if dbKey then _currentSection.dbKeys[#_currentSection.dbKeys + 1] = dbKey end
        -- If the section was restored as collapsed BEFORE any children were
        -- registered, the children would otherwise stay visible and bleed
        -- over the next section's content. Hide newcomers immediately.
        if _currentSection._collapsed and widget.Hide then
            widget:Hide()
        end
    end
end

-- ============================================================
-- "NEW" BADGE
-- ============================================================

-- ============================================================
-- WIDGET FACTORIES
-- ============================================================






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

local SECTION_GAP = 28  -- vertical pixels between section containers
local COLLAPSED_HEIGHT = 22

local function makeSection(parent, title, x, y, key)
    local section = {
        children = {},
        dbKeys = {},
        key = key,
        _originalY = y,
        _parent = parent,
    }

    -- Container frame: chains under the previous section on this page.
    -- Collapsing one container shrinks it, which automatically pulls every
    -- subsequent section up the page.
    local container = CreateFrame("Frame", nil, parent)
    local prev = _lastSectionOnPage[parent]
    if prev then
        container:SetPoint("TOPLEFT",  prev.container, "BOTTOMLEFT", 0, -SECTION_GAP)
        container:SetPoint("TOPRIGHT", parent,         "TOPRIGHT",   0, 0)
    else
        -- First section on the page anchors at the requested y offset.
        container:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, y)
        container:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
    end
    container:SetHeight(COLLAPSED_HEIGHT)
    section.container = container
    section._searchText = (title or ""):lower()
    _lastSectionOnPage[parent] = section
    _allSectionsOnPage[parent] = _allSectionsOnPage[parent] or {}
    _allSectionsOnPage[parent][#_allSectionsOnPage[parent] + 1] = section

    -- Header inside the container at (x, 0)
    local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", container, "TOPLEFT", x, 0)
    header:SetTextColor(1, 0.82, 0)
    header:SetText(title)
    section.header = header

    -- Chevron (collapsed indicator) — Blizzard PlusMinus textures
    local chevron = container:CreateTexture(nil, "OVERLAY")
    chevron:SetSize(14, 14)
    chevron:SetPoint("LEFT", header, "RIGHT", 4, -1)
    section.chevron = chevron
    local TEX_EXPANDED  = "Interface\\Buttons\\UI-MinusButton-Up"
    local TEX_COLLAPSED = "Interface\\Buttons\\UI-PlusButton-Up"

    -- Invisible click area covering the header strip
    local clickArea = CreateFrame("Button", nil, container)
    clickArea:SetPoint("TOPLEFT",  container, "TOPLEFT",  x - 14, -2)
    clickArea:SetPoint("TOPRIGHT", container, "TOPRIGHT", -40,    -2)
    clickArea:SetHeight(18)
    clickArea:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    section.clickArea = clickArea

    -- Reset section button (refresh icon, same pattern as TankWatch)
    local btnReset = CreateFrame("Button", nil, container)
    btnReset:SetSize(14, 14)
    btnReset:SetPoint("TOPRIGHT", container, "TOPRIGHT", -14, -1)
    btnReset:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
    btnReset:GetNormalTexture():SetTexCoord(0.05, 0.95, 0.05, 0.95)
    btnReset:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    section.resetBtn = btnReset

    local line = container:CreateTexture(nil, "OVERLAY")
    line:SetHeight(1)
    line:SetColorTexture(1, 0.82, 0, 0.55)
    section.line = line

    local function placeLine()
        local hw = header:GetStringWidth() or 0
        local startX = x + hw + 4 + 14 + 8
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT",  container, "TOPLEFT",  startX, -7)
        line:SetPoint("TOPRIGHT", container, "TOPRIGHT", -42,    -7)
    end
    placeLine()
    C_Timer.After(0, placeLine)

    function section:UpdateNaturalHeight()
        if self._collapsed then
            self.container:SetHeight(COLLAPSED_HEIGHT)
            return
        end
        local cTop = self.container:GetTop()
        if not cTop then
            C_Timer.After(0, function() self:UpdateNaturalHeight() end)
            return
        end
        local lowest, gotAnyChildPos = cTop, false
        for _, w in ipairs(self.children) do
            if w.IsShown and w:IsShown() and w.GetBottom then
                local b = w:GetBottom()
                if b then
                    gotAnyChildPos = true
                    if b < lowest then lowest = b end
                end
            end
        end
        -- If we have children but none have a resolved bottom yet, defer.
        -- Otherwise the container shrinks to COLLAPSED_HEIGHT, the next section
        -- anchors right under it, and you get a stack of overlapping rows.
        if not gotAnyChildPos and #self.children > 0 then
            C_Timer.After(0, function() self:UpdateNaturalHeight() end)
            return
        end
        local span = math.max(COLLAPSED_HEIGHT, cTop - lowest + 8)
        self.container:SetHeight(span)
    end

    function section:SetCollapsed(state, persist)
        state = state and true or false
        for _, w in ipairs(self.children) do
            if state then if w.Hide then w:Hide() end
            else            if w.Show then w:Show() end end
        end
        chevron:SetTexture(state and TEX_COLLAPSED or TEX_EXPANDED)
        if persist and self.key then
            BossWatchDB = BossWatchDB or {}
            BossWatchDB.collapsedSections = BossWatchDB.collapsedSections or {}
            BossWatchDB.collapsedSections[self.key] = state or nil
        end
        self._collapsed = state
        if state then
            self.container:SetHeight(COLLAPSED_HEIGHT)
        else
            self:UpdateNaturalHeight()
        end
    end

    function section:Toggle()
        self:SetCollapsed(not self._collapsed, true)
    end

    function section:ResetToDefaults()
        local db = BossW:GetDB()
        for _, k in ipairs(self.dbKeys) do
            local def = (BossW.Defaults or {})[k]
            if def ~= nil then db[k] = _cloneDefault(def) end
        end
        if BossW.RefreshAll then BossW:RefreshAll() end
        if BossW.ApplyFonts then BossW:ApplyFonts() end
        if panel and panel.refreshAll then panel.refreshAll() end
    end

    clickArea:SetScript("OnClick", function() section:Toggle() end)
    btnReset:SetScript("OnClick", function() section:ResetToDefaults() end)

    -- Restore collapsed state from DB
    BossWatchDB = BossWatchDB or {}
    local restored = BossWatchDB.collapsedSections and key and BossWatchDB.collapsedSections[key]
    section:SetCollapsed(restored or false, false)

    -- Tooltips
    if addTooltip then
        addTooltip(clickArea, L["Click to collapse/expand this section."])
        addTooltip(btnReset,  L["Reset this section to default values."])
    end

    -- Subsequent makeXxx() / _registerInSection() calls will attach to this section.
    _currentSection = section
    return section
end

-- Hover tooltip helper. Hooks the widget AND any well-known child controls
-- (slider thumb, steppers) so the tooltip shows everywhere on composite widgets.


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
    changelog= L["Release notes and recent changes."],
}

local function makeTab(parent, id, label, idx, prevTab)
    -- Bottom-anchored tab (like Auction House / Profession panels).
    -- Anchoring is deferred to layoutTabs() so multi-row wrapping can apply
    -- when the panel is too narrow to fit all tabs in a single row.
    local tab = CreateFrame("Button", "BWTab"..id, parent, "PanelTabButtonTemplate")
    tab:SetText(label)
    tab.id = id
    if PanelTemplates_TabResize then PanelTemplates_TabResize(tab, 0) end
    if TAB_TOOLTIPS[id] then addTooltip(tab, TAB_TOOLTIPS[id]) end

    -- ONLY on clients where PanelTabButtonTemplate atlas regions render
    -- as bare text (Classic Era / TBC Anniversary) do we add a manual
    -- dark backdrop + thin border so the tab has a visible button shape.
    -- Retail / Midnight / MoP get the native Blizzard look untouched.
    if BossW._sodMode then
        local bg = tab:CreateTexture(nil, "BACKGROUND", nil, -2)
        bg:SetPoint("TOPLEFT", 2, -3)
        bg:SetPoint("BOTTOMRIGHT", -2, 3)
        bg:SetColorTexture(0.08, 0.08, 0.08, 0.85)
        tab._fallbackBg = bg

        local edge = tab:CreateTexture(nil, "BACKGROUND", nil, -1)
        edge:SetPoint("TOPLEFT", 1, -2)
        edge:SetPoint("BOTTOMRIGHT", -1, 2)
        edge:SetColorTexture(0.35, 0.28, 0.10, 1)
        tab._fallbackEdge = edge

        local fs = tab:GetFontString()
        if fs then fs:SetDrawLayer("OVERLAY") end
    end

    return tab
end

-- ============================================================
-- EXPOSE HELPERS TO EXTERNAL PAGE FILES (Options/Pages/*.lua)
-- ============================================================
-- All factory functions and helpers used by page builders live here as
-- locals. External page files cannot see closure-captured locals, so we
-- mirror them onto BossW.Options. Page files do `local O = BossW.Options`
-- at the top and then `local makeSection = O.makeSection` etc.
-- Widget factories (addTooltip, makeSlider, etc.) are defined in
-- Options/Widgets.lua. Only the section system + section state stay here.
O._registerInSection  = _registerInSection
O.makeSection         = makeSection
-- Setter so external files can reset _currentSection (e.g. pages that have
-- no makeSection of their own — About, Profiles — must clear it so widgets
-- created there don't auto-register into the previous page's last section).
O.setCurrentSection   = function(v) _currentSection = v end
-- Accessor for the panel frame (used by About's "reset window" button and
-- by Profiles' refreshAll calls). The panel is a local in this file so
-- external page files can't see it directly.
O.GetPanel            = function() return panel end
O.refreshPanel        = function() if panel and panel.refreshAll then panel.refreshAll() end end

-- ============================================================
-- PAGE BUILDERS
-- All page builders live in Options/Pages/*.lua and register themselves
-- into O.Pages.<id> at file load. The TOC loads those files AFTER this
-- file, so O.Pages.* is populated by the time build() runs.
-- ============================================================


-- ============================================================
-- BUILD
-- ============================================================

local function build()
    -- Modern Blizzard 11.0 portrait frame (used by Item Upgrades, Adventure Guide, etc.)
    panel = CreateFrame("Frame", "BossWatchOptions", UIParent, "PortraitFrameTemplate")
    BossWatchDB = BossWatchDB or {}
    -- Clamp saved size to current UIParent dimensions. Protects users who
    -- enlarged the panel on a larger monitor then relaunched on a smaller
    -- screen — the saved size would otherwise make the panel overflow.
    local pw, ph = UIParent:GetWidth(), UIParent:GetHeight()
    local startW = math.min(pw - 40, math.max(720, BossWatchDB.panelW or 720))
    local startH = math.min(ph - 40, math.max(500, BossWatchDB.panelH or 620))
    panel:SetSize(startW, startH)
    if BossWatchDB.panelPoint then
        local p = BossWatchDB.panelPoint
        -- Clamp saved offsets too — SetClampedToScreen only kicks in on
        -- subsequent drags, not on initial placement.
        if math.abs(p.x or 0) > pw then p.x = 0 end
        if math.abs(p.y or 0) > ph then p.y = 0 end
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

    -- Search bar (top-right of the title area)
    local searchBox = CreateFrame("EditBox", "BWOpt_Search", panel, "InputBoxTemplate")
    searchBox:SetSize(200, 22)
    searchBox:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -38, -32)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(40)
    searchBox:SetFontObject("GameFontHighlight")
    searchBox:SetTextInsets(20, 18, 0, 0)

    local searchIcon = searchBox:CreateTexture(nil, "OVERLAY")
    searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    searchIcon:SetSize(14, 14)
    searchIcon:SetPoint("LEFT", searchBox, "LEFT", 4, 0)

    local searchPlaceholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    searchPlaceholder:SetPoint("LEFT", searchIcon, "RIGHT", 4, 0)
    searchPlaceholder:SetText(L["Search options…"])

    local searchClear = CreateFrame("Button", nil, searchBox)
    searchClear:SetSize(16, 16)
    searchClear:SetPoint("RIGHT", searchBox, "RIGHT", -2, 0)
    searchClear:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
    searchClear:Hide()

    local function runSearch(text)
        searchPlaceholder:SetShown(text == "")
        searchClear:SetShown(text ~= "")
        _applySearch(text)
    end

    searchBox:SetScript("OnTextChanged", function(self) runSearch(self:GetText()) end)
    searchBox:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    searchBox:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)
    searchClear:SetScript("OnClick", function() searchBox:SetText(""); searchBox:ClearFocus() end)
    addTooltip(searchBox, L["Filter the panel: type any keyword from a label or tooltip. Sections without a match are auto-collapsed."])
    addTooltip(searchClear, L["Clear the search."])

    -- Classic build banner — only visible on non-retail clients.
    -- Message differs between MoP/Cata/Wrath/TBC (still uses boss1..5 unit IDs
    -- natively) and Classic Era / SoD (boss1..5 don't exist — see SoD tab).
    if WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
        local banner = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        -- Anchored LEFT (not centered TOP) so it doesn't run under the
        -- search box at TOPRIGHT. Width is bounded so long messages wrap
        -- instead of overflowing into the search column.
        banner:SetPoint("TOPLEFT", panel, "TOPLEFT", 80, -34)
        banner:SetWidth(420)
        banner:SetJustifyH("LEFT")
        banner:SetTextColor(1, 0.82, 0)
        local msg
        if BossW._sodMode then
            msg = L["⚠ Classic Era / SoD build — bosses are detected via target + nameplates (see the Classic / SoD tab). Report bugs!"]
        else
            msg = L["⚠ Classic build — UI not fully tested in encounters yet, please report bugs."]
        end
        banner:SetText("|cffffd100" .. msg .. "|r")
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

    local function buildPage(name, fn)
        local p = newPage(name)
        fn(p.content)
        -- Recompute every section's natural height now that all children are anchored.
        C_Timer.After(0, function() _refreshHeightsForPage(p.content) end)
        autoFitPage(p)
        return p
    end

    pages.layout   = buildPage("layout",   O.Pages.layout)
    pages.bars     = buildPage("bars",     O.Pages.bars)
    pages.cast     = buildPage("cast",     O.Pages.cast)
    pages.text     = buildPage("text",     O.Pages.text)
    pages.raid     = buildPage("raid",     O.Pages.raid)
    pages.auras    = buildPage("auras",    O.Pages.auras)
    pages.profiles = buildPage("profiles", O.Pages.profiles)
    pages.about    = buildPage("about",    O.Pages.about)
    -- SoD page is only built (and tab only shown) when the SodSlotProvider
    -- is loaded — i.e. on any client without native boss1..5 unit IDs.
    if BossW._sodMode and O.Pages.sod then
        pages.sod  = buildPage("sod",      O.Pages.sod)
    end
    -- Changelog is no longer a tab — it's a section at the bottom of About.

    -- Hidden "search results" page — not in the tab list. When the search box
    -- has a query, every matching widget group is reparented here on the fly,
    -- with a breadcrumb pointing back to its real tab/section.
    local resultsPage = newPage("results")
    local resultsContent = resultsPage.content
    pages._results = resultsPage  -- registered so we can hide it via the for-loop

    local breadcrumbPool = {}
    local activeMatches = {}    -- widgets currently moved out to results
    local lastNormalTabId = "layout"

    local function _moveGroupToResults(w, y)
        if not w._searchGroup then return y end
        for _, comp in ipairs(w._searchGroup) do
            if comp and comp.SetParent then
                comp:SetParent(resultsContent)
                if comp.Show then comp:Show() end
            end
        end
        local leader = w._searchGroup[1]
        if leader and leader.ClearAllPoints then
            leader:ClearAllPoints()
            leader:SetPoint("TOPLEFT", resultsContent, "TOPLEFT", 14, y)
        end
        return y - 64  -- breadcrumb (14) + widget row (~50)
    end

    local function _restoreGroupHome(w)
        if not w._searchGroup then return end
        for _, comp in ipairs(w._searchGroup) do
            if comp and comp._homeContainer and comp.SetParent then
                comp:SetParent(comp._homeContainer)
            end
            if comp and comp._homeAnchors and comp.ClearAllPoints then
                comp:ClearAllPoints()
                for _, a in ipairs(comp._homeAnchors) do
                    comp:SetPoint(a.p, a.relTo, a.relPoint, a.x, a.y)
                end
            end
        end
    end

    local function _gatherMatches(query)
        local matches = {}
        for _, sections in pairs(_allSectionsOnPage) do
            for _, section in ipairs(sections) do
                for _, w in ipairs(section.children) do
                    local txt = w._searchText
                    if txt and w._searchGroup and txt:lower():find(query, 1, true) then
                        matches[#matches + 1] = w
                    end
                end
            end
        end
        return matches
    end

    -- Real search implementation, assigned to the forward-declared upvalue.
    _searchImpl = function(rawQuery)
        local q = (rawQuery or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        local empty = (q == "")

        -- Always clear out the previous results state first
        for _, w in ipairs(activeMatches) do _restoreGroupHome(w) end
        wipe(activeMatches)
        for _, fs in ipairs(breadcrumbPool) do fs:Hide() end

        if empty then
            resultsPage:Hide()
            for _, p in pairs(pages) do
                if p ~= resultsPage then p:Hide() end
            end
            if pages[lastNormalTabId] then pages[lastNormalTabId]:Show() end
            for _, ref in ipairs(_searchTabRefs) do
                ref.btn:SetText(ref.label)
                if PanelTemplates_TabResize then PanelTemplates_TabResize(ref.btn, 0) end
            end
            return
        end

        local matches = _gatherMatches(q)

        -- Hide every regular page and show the results page instead
        for _, p in pairs(pages) do
            if p ~= resultsPage then p:Hide() end
        end

        local hitsByPage = {}
        local y = -10
        for i, w in ipairs(matches) do
            local fs = breadcrumbPool[i]
            if not fs then
                fs = resultsContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                breadcrumbPool[i] = fs
            end
            fs:Show()
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", resultsContent, "TOPLEFT", 14, y)
            local section = w._homeSection
            local sectionTitle = (section and section.header and section.header:GetText()) or "?"
            local pageContent = section and section._parent
            local tabLabel = "?"
            for _, ref in ipairs(_searchTabRefs) do
                if ref.content == pageContent then tabLabel = ref.label; break end
            end
            fs:SetText("|cff888888" .. tabLabel .. "  >  " .. sectionTitle .. "|r")

            if pageContent then hitsByPage[pageContent] = (hitsByPage[pageContent] or 0) + 1 end

            y = y - 14  -- breadcrumb height + small gap before widget
            y = _moveGroupToResults(w, y)
            activeMatches[#activeMatches + 1] = w
        end

        if #matches == 0 then
            local fs = breadcrumbPool[1]
            if not fs then
                fs = resultsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                breadcrumbPool[1] = fs
            end
            fs:Show()
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", resultsContent, "TOPLEFT", 14, -20)
            fs:SetText(L["No options match your search."])
        end

        resultsContent:SetHeight(math.max(resultsPage:GetHeight(), math.abs(y) + 24))
        resultsPage:Show()

        -- Update tab labels with hit counts (so the user sees where matches live
        -- once they clear the search and want to dive in normally).
        for _, ref in ipairs(_searchTabRefs) do
            local n = hitsByPage[ref.content] or 0
            if n == 0 then
                ref.btn:SetText(ref.label)
            else
                ref.btn:SetText(ref.label .. " |cffeda14a(" .. n .. ")|r")
            end
            if PanelTemplates_TabResize then PanelTemplates_TabResize(ref.btn, 0) end
        end
    end

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
    if BossW._sodMode then
        table.insert(tabs, #tabs, { id = "sod", label = L["Classic / SoD"] })
    end
    local tabBtns = {}
    local function selectTab(id)
        -- If a search is active, clear it before switching (which restores the
        -- widgets reparented to the results page).
        if searchBox and searchBox:GetText() ~= "" then
            searchBox:SetText("")
        end
        lastNormalTabId = id
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

    wipe(_searchTabRefs)
    for i, t in ipairs(tabs) do
        local b = makeTab(panel, t.id, t.label, i, tabBtns[i - 1])
        b:SetScript("OnClick", function() selectTab(t.id) end)
        tabBtns[#tabBtns + 1] = b
        if pages[t.id] and pages[t.id].content then
            _searchTabRefs[#_searchTabRefs + 1] = {
                btn = b, content = pages[t.id].content, label = t.label,
            }
        end
    end

    -- Wrap tabs into multiple rows when the panel is too narrow to fit them
    -- all in a single row. Re-runs on resize.
    local function layoutTabs()
        local available = panel:GetWidth() - 24  -- 12px margin each side
        local x, y = 12, 2
        local rowH = 24
        local row = 0
        local baseLevel = panel:GetFrameLevel()
        for _, tab in ipairs(tabBtns) do
            local w = tab:GetWidth()
            if x > 12 and (x + w) > available + 12 then
                x = 12
                y = y - rowH
                row = row + 1
            end
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", x, y)
            -- Lower rows must draw ABOVE upper rows so their top edges
            -- (which bridge to the panel border) read clean instead of
            -- being clipped under the row above.
            tab:SetFrameLevel(baseLevel + 2 + row * 2)
            x = x + w + 2
        end
    end
    layoutTabs()
    panel:HookScript("OnSizeChanged", layoutTabs)

    panel.refreshAll = function()
        local db = BossW:GetDB()
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

    -- =====================================================================
    -- Sister-addon side tabs (left edge of the panel, like the PvP / Pet
    -- Battle frame's category tabs). The current addon's tab is the first
    -- and stays selected; sister addons (TankWatch) appear below it ONLY if
    -- the addon is loaded. Click a sister tab → close this panel + open theirs.
    -- =====================================================================
    local SIDE_TAB_SIZE = 48
    local sideTabs = {
        { id = "BossWatch",  isSelf = true,  icon = "Interface\\AddOns\\BossWatch\\Media\\logo.png",
          tooltip = L["BossWatch — Options"], onClick = function() end },
        { id = "TankWatch",  isSelf = false, icon = "Interface\\AddOns\\TankWatch\\Media\\icon",
          tooltip = L["Open TankWatch options"],
          loadedCheck = function()
              local TW = _G.TankWatch
              return C_AddOns and C_AddOns.IsAddOnLoaded
                     and C_AddOns.IsAddOnLoaded("TankWatch")
                     and TW and TW.ToggleOptions
          end,
          onClick = function()
              local point, _, relPoint, x, y
              if panel and panel:IsShown() then
                  point, _, relPoint, x, y = panel:GetPoint(1)
                  panel:Hide()
              end
              local TW = _G.TankWatch
              if TW and TW.ShowOptionsAt and point then
                  TW:ShowOptionsAt(point, relPoint, x, y)
              elseif TW and TW.ToggleOptions then
                  TW:ToggleOptions()
              end
          end },
        { id = "SplitWatch", isSelf = false, icon = "Interface\\AddOns\\SplitWatch\\Media\\logo.png",
          tooltip = L["Open SplitWatch options"],
          loadedCheck = function()
              local SplitW = _G.SplitWatch
              return C_AddOns and C_AddOns.IsAddOnLoaded
                     and C_AddOns.IsAddOnLoaded("SplitWatch")
                     and SplitW and SplitW.ToggleOptions
          end,
          onClick = function()
              local point, _, relPoint, x, y
              if panel and panel:IsShown() then
                  point, _, relPoint, x, y = panel:GetPoint(1)
                  panel:Hide()
              end
              local SplitW = _G.SplitWatch
              if SplitW and SplitW.ShowOptionsAt and point then
                  SplitW:ShowOptionsAt(point, relPoint, x, y)
              elseif SplitW and SplitW.ToggleOptions then
                  SplitW:ToggleOptions()
              end
          end },
    }

    local visibleIdx = 0
    for _, def in ipairs(sideTabs) do
        if def.isSelf or (def.loadedCheck and def.loadedCheck()) then
            visibleIdx = visibleIdx + 1

            local tab = CreateFrame("Button", nil, panel, "BackdropTemplate")
            tab:SetSize(SIDE_TAB_SIZE, SIDE_TAB_SIZE)
            tab:SetPoint("TOPLEFT", panel, "TOPLEFT", -SIDE_TAB_SIZE + 8,
                         -68 - (visibleIdx - 1) * (SIDE_TAB_SIZE + 8))
            tab:SetFrameLevel(panel:GetFrameLevel() + 5)

            -- Dark vignette backdrop — no edge, we draw our own borders
            tab:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            tab:SetBackdropColor(0.04, 0.04, 0.07, 0.95)

            -- Soft inner highlight at the top (vertical gradient)
            local sheen = tab:CreateTexture(nil, "ARTWORK")
            sheen:SetPoint("TOPLEFT",     tab, "TOPLEFT",      1, -1)
            sheen:SetPoint("BOTTOMRIGHT", tab, "TOPRIGHT",    -1, -math.floor(SIDE_TAB_SIZE * 0.45))
            sheen:SetColorTexture(1, 1, 1, 1)
            if sheen.SetGradient and CreateColor then
                sheen:SetGradient("VERTICAL",
                    CreateColor(1, 1, 1, 0.10),
                    CreateColor(1, 1, 1, 0.00))
            else
                sheen:SetVertexColor(1, 1, 1, 0.06)
            end

            -- Bottom subtle shadow
            local shade = tab:CreateTexture(nil, "ARTWORK")
            shade:SetPoint("BOTTOMLEFT",  tab, "BOTTOMLEFT",   1,  1)
            shade:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -1,  1)
            shade:SetHeight(math.floor(SIDE_TAB_SIZE * 0.40))
            shade:SetColorTexture(0, 0, 0, 1)
            if shade.SetGradient and CreateColor then
                shade:SetGradient("VERTICAL",
                    CreateColor(0, 0, 0, 0.00),
                    CreateColor(0, 0, 0, 0.45))
            else
                shade:SetVertexColor(0, 0, 0, 0.20)
            end

            -- Icon — round-ish, generously inset, with a tex-coord crop
            -- so logo edges don't touch the border
            local icon = tab:CreateTexture(nil, "ARTWORK", nil, 2)
            icon:SetPoint("CENTER", tab, "CENTER", 0, 0)
            icon:SetSize(SIDE_TAB_SIZE - 14, SIDE_TAB_SIZE - 14)
            icon:SetTexture(def.icon)
            icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)

            -- Hand-drawn border (4 thin lines), gold when active
            local function makeEdge(point1, point2, w, h)
                local t = tab:CreateTexture(nil, "BORDER")
                t:SetPoint(point1, tab, point1, 0, 0)
                t:SetPoint(point2, tab, point2, 0, 0)
                if w then t:SetWidth(w) end
                if h then t:SetHeight(h) end
                return t
            end
            local edges = {
                makeEdge("TOPLEFT", "TOPRIGHT", nil, 1),
                makeEdge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1),
                makeEdge("TOPLEFT", "BOTTOMLEFT", 1, nil),
                makeEdge("TOPRIGHT", "BOTTOMRIGHT", 1, nil),
            }
            local function setEdgeColor(r, g, b, a)
                for _, t in ipairs(edges) do t:SetColorTexture(r, g, b, a) end
            end
            setEdgeColor(0.20, 0.20, 0.24, 1)

            -- Outer glow ring (additive gold), shown when active or hovered
            local glow = tab:CreateTexture(nil, "OVERLAY")
            glow:SetPoint("TOPLEFT",     tab, "TOPLEFT",     -10,  10)
            glow:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT",  10, -10)
            glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            glow:SetBlendMode("ADD")
            glow:SetVertexColor(1, 0.82, 0, 0.85)
            glow:Hide()

            -- Selected accent: a thicker, brighter stripe along the panel-side edge
            local marker = tab:CreateTexture(nil, "OVERLAY", nil, 1)
            marker:SetPoint("TOPRIGHT",    tab, "TOPRIGHT",    -0.5, -3)
            marker:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -0.5,  3)
            marker:SetWidth(3)
            marker:SetColorTexture(1, 0.82, 0, 1)
            marker:Hide()

            if def.isSelf then
                setEdgeColor(1, 0.82, 0, 1)
                glow:Show()
                marker:Show()
                tab:EnableMouse(false)
            else
                tab:HookScript("OnEnter", function()
                    setEdgeColor(1, 0.82, 0, 1)
                    glow:Show()
                end)
                tab:HookScript("OnLeave", function()
                    setEdgeColor(0.20, 0.20, 0.24, 1)
                    glow:Hide()
                end)
                tab:SetScript("OnClick", def.onClick)
            end

            addTooltip(tab, def.tooltip)
        end
    end
end

function BossW:ToggleOptions()
    if not panel then build() end
    if panel:IsShown() then panel:Hide()
    else panel.refreshAll(); panel:Show() end
end

-- Cross-addon handoff: open the panel at a specific position, used by sister
-- addons (TankWatch) when switching via side tabs so the window doesn't jump
-- to its previously-saved spot. Coordinates are persisted, so reopening later
-- from the minimap / slash command will land in the same place.
function BossW:ShowOptionsAt(point, relPoint, x, y)
    if not panel then build() end
    if point then
        panel:ClearAllPoints()
        panel:SetPoint(point, UIParent, relPoint or point, x or 0, y or 0)
        BossWatchDB.panelPoint = {
            point = point, relPoint = relPoint or point,
            x = math.floor((x or 0) + 0.5),
            y = math.floor((y or 0) + 0.5),
        }
    end
    panel.refreshAll()
    panel:Show()
end

function BossW:RegisterBlizzardSettings()
    if BossW._settingsCategoryID or not Settings or not Settings.RegisterCanvasLayoutCategory then
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
        if not panel or not panel:IsShown() then BossW:ToggleOptions() end
    end)
    addTooltip(btn, L["Open the floating BossWatch options panel."])

    local hint = host:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -10)
    hint:SetText(L["You can also use the slash command: /bossw"])

    local category = Settings.RegisterCanvasLayoutCategory(host, "BossWatch")
    category.ID = "BossWatch"
    Settings.RegisterAddOnCategory(category)
    BossW._settingsCategoryID = category:GetID()
end
