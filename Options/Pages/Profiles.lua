local addonName, BossW = ...
local L = BossW.L
local O = BossW.Options

local addTooltip = O.addTooltip

local CreateFrame = CreateFrame
local format = string.format
local ipairs, tostring = ipairs, tostring

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

function O.Pages.profiles(page)
    O.setCurrentSection(nil)  -- this page has no makeSection — widgets shouldn't register
    local y = -10

    -- Character label
    local charLabel = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    charLabel:SetPoint("TOPLEFT", 14, y)
    charLabel:SetText(L["Character:"] .. " |cffffffff" .. (BossW:GetCharKey()) .. "|r")

    y = y - 24

    -- Active profile dropdown
    local labelFS = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    labelFS:SetPoint("TOPLEFT", 14, y)
    labelFS:SetText(L["Active profile"])

    local dd = CreateFrame("DropdownButton", "BWOpt_DD_activeProfile", page, "WowStyle1DropdownTemplate")
    dd:SetPoint("TOPLEFT", labelFS, "BOTTOMLEFT", 0, -2)
    dd:SetWidth(220)

    dd:SetupMenu(function(_, rootDescription)
        for _, name in ipairs(BossW:ListProfiles()) do
            rootDescription:CreateRadio(name,
                function() return name == BossW:GetActiveProfileName() end,
                function()
                    BossW:SetActiveProfile(name)
                    O.refreshPanel()
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
            local ok = BossW:CreateProfile(name)
            if ok then
                BossW:SetActiveProfile(name)
                profileDropdownRefresh()
                O.refreshPanel()
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
        local name = BossW:GetActiveProfileName()
        showConfirmPopup(format(L["Reset profile '%s' to defaults?"], name), function()
            BossW:ResetProfile(name)
            if BossW.RefreshAll then BossW:RefreshAll() end
            if BossW.ApplyFonts then BossW:ApplyFonts() end
            O.refreshPanel()
        end)
    end)

    local btnDelete = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    btnDelete:SetSize(110, 22)
    btnDelete:SetPoint("LEFT", btnReset, "RIGHT", 6, 0)
    btnDelete:SetText(L["Delete"])
    addTooltip(btnDelete, L["Delete the active profile (cannot delete Default)."])
    btnDelete:SetScript("OnClick", function()
        local name = BossW:GetActiveProfileName()
        if name == "Default" then
            print("|cffeda55fBossWatch:|r " .. L["cannot delete Default"])
            return
        end
        showConfirmPopup(format(L["Delete profile '%s'?"], name), function()
            BossW:DeleteProfile(name)
            profileDropdownRefresh()
            if BossW.RefreshAll then BossW:RefreshAll() end
            if BossW.ApplyFonts then BossW:ApplyFonts() end
            O.refreshPanel()
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
        local s = BossW:ExportProfile()
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
                local ok, err = BossW:ImportProfile(text, name, overwrite)
                if ok then
                    BossW:SetActiveProfile(name)
                    profileDropdownRefresh()
                    O.refreshPanel()
                    print("|cffeda55fBossWatch:|r " .. format(L["profile '%s' imported"], name))
                else
                    print("|cffeda55fBossWatch:|r " .. L["import failed:"] .. " " .. tostring(err))
                end
            end

            -- First try without overwrite; if name exists, prompt to overwrite.
            local ok, err = BossW:ImportProfile(text, name, false)
            if ok then
                BossW:SetActiveProfile(name)
                profileDropdownRefresh()
                O.refreshPanel()
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
