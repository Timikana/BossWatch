local addonName, BossW = ...
local L = BossW.L
local O = BossW.Options

local addTooltip = O.addTooltip

local CreateFrame = CreateFrame
local C_AddOns = C_AddOns
local ipairs = ipairs
local MinimalSliderWithSteppersMixin = MinimalSliderWithSteppersMixin

local function buildChangelogSection(parent, anchorWidget)
    local page = parent  -- alias for legacy var name below

    -- Per-version blocks. Each entry: { version, date, lines = { ... } }
    local entries = {
        { ver = "v0.7.7", date = "2026-05-12", lines = {
            L["Internal: options panel split across multiple files — one file per tab under Options/Pages/, widget factories isolated in Options/Widgets.lua. No user-visible change; the code base is just cleaner for future work."],
            L["Internal: CI lint (luacheck) runs on every push to catch syntax errors before release."],
        }},
        { ver = "v0.7.6", date = "2026-05-12", lines = {
            L["Hotfix: the options window is now clamped to current screen bounds on load — no more panel stuck off-screen after switching from a larger monitor to a smaller one."],
        }},
        { ver = "v0.7.5", date = "2026-05-12", lines = {
            L["Changelog moved from a separate bottom tab into a section at the bottom of the About tab — one less tab to scan, version history sits next to the version number naturally."],
            L["New 3rd side tab slot on the left edge of the panel for SplitWatch (sister addon, appears when installed)."],
            L["Internal: release notes now live in a single CHANGELOG.md at repo root instead of one file per version. Easier to read on GitHub."],
        }},
        { ver = "v0.7.4", date = "2026-05-11", lines = {
            L["Hotfix: smooth health bar finally stops spamming Lua errors on bosses with secret-tagged StatusBar state — we now detect the taint before doing the math instead of trying to catch it (Blizzard's taint logger isn't pcall-catchable)."],
            L["Modernised aura collection: now uses C_UnitAuras.GetUnitAuraInstanceIDs with native sort rules, so boss debuffs are ordered by Blizzard's own priority instead of raw index order. Legacy fallback preserved for Classic."],
        }},
        { ver = "v0.7.3", date = "2026-05-11", lines = {
            L["Boss frames now auto-recover when the saved position falls off-screen (e.g. moved on a larger monitor then relaunched on a smaller one) — coords are clamped to current screen bounds on load."],
            L["New debug command /bossw auras [unit] — prints every aura on each boss (or the given unit) with a color-coded readout of which fields Blizzard exposes vs hides as secret values."],
        }},
        { ver = "v0.7.2", date = "2026-05-10", lines = {
            L["Hover an aura icon on a boss frame to see its standard Blizzard tooltip — name, description, remaining duration. Toggle in Auras > Display."],
        }},
        { ver = "v0.7.1", date = "2026-05-10", lines = {
            L["Hotfix: smooth health bar no longer spams Lua errors when a boss returns a secret-tagged HP value (the bar falls back to direct, non-animated updates on those bosses)."],
            L["Hotfix: raid target icons (skull, cross…) placed on bosses during combat now display correctly on the BossWatch frame instead of staying hidden."],
        }},
        { ver = "v0.7.0", date = "2026-05-10", lines = {
            L["Mists of Pandaria Classic support: a single zip now installs on retail and MoP Classic."],
            L["New slash command: /bossw (with alias /bosswatch). The old /bw is gone — that prefix collides with BigWigs."],
            L["Bottom tabs now wrap onto a second row when the panel is too narrow, with proper layering so nothing gets clipped."],
            L["Switching between BossWatch and TankWatch via the side tabs now keeps the window in place — no more jumping to the other addon's saved position."],
            L["Boss debuffs are detected more reliably on Classic clients (uses the native isBossDebuff flag instead of name-matching)."],
            L["A yellow banner appears at the top of the panel on Classic builds, flagging that the UI is not yet fully tested in encounters."],
        }},
        { ver = "v0.6.1", date = "2026-05-10", lines = {
            L["Addon side tabs on the left edge of the panel: switch between BossWatch and TankWatch with one click (the second tab only appears when the sister addon is installed)."],
            L["Modern look on the side tabs: dark glass backdrop, gold accent stripe on the active addon, glow ring on hover."],
        }},
        { ver = "v0.6.0", date = "2026-05-10", lines = {
            L["Search bar (top-right) gathers matches from every tab onto a single Results page — Blizzard-style. Tabs show a (N) badge per hit count."],
            L["Collapsible sections with a refresh icon to reset just that section to defaults."],
            L["Resizable options window: drag the bottom-right grip; size and position saved account-wide. New 'Reset window size' button in About."],
            L["Auto-flow: right-column controls (sliders, checks, dropdowns, color pickers) slide along the right edge when the panel is widened."],
            L["Click actions on boss frames: Shift+Click cycles raid markers, Ctrl+Click sets focus. Toggle in Layout > General."],
            L["Smooth health bar animation (toggle in Bars > Health)."],
            L["This Changelog tab so you can see what changed without leaving the game."],
            L["Lots of small UX polish: section dividers stretch with the panel width, dropdown labels stay anchored above their control, more tooltips, etc."],
        }},
        { ver = "v0.5.1", date = "2026-05-10", lines = {
            L["Compatibility with WoW patch 12.0.7 (no more out-of-date warning)."],
        }},
        { ver = "v0.5.0", date = "2026-05-10", lines = {
            L["Damage absorption / shields are now drawn over the boss health bar."],
            L["Modernized options panel using the WoW 11/12 portrait style."],
            L["Highlight border around the boss frame matching your current target (with optional pulse)."],
            L["3-block (compact) or 4-block (name on its own row) layout."],
            L["Themed test mode: Lich King, Kel'Thuzad, Onyxia, Ragnaros, Illidan."],
            L["Full localization: French, German, Spanish, Italian, Brazilian Portuguese."],
            L["Tooltips on every control, including the bottom tabs."],
            L["Search bar (top-right of the panel) gathers matches from every tab onto a Results page — Blizzard-style."],
            L["Collapsible sections with a per-section reset button (refresh icon)."],
            L["Resizable options window: drag the bottom-right grip; size and position are saved account-wide."],
            L["Auto-flow: right-column controls slide along with the right edge when the panel is widened."],
            L["Click actions on boss frames: Shift+Click cycles raid markers, Ctrl+Click sets focus."],
            L["Smooth health bar animation."],
        }},
        { ver = "v0.4.x", date = "2026-04", lines = {
            L["Modern UI portrait frame, scrollable LSM media dropdowns with previews."],
            L["Profile import/export with overwrite confirmation."],
            L["Polished defaults for textures and font, fixed bugs around HP/Power text on hostile bosses."],
        }},
        { ver = "v0.3.x", date = "2026-03", lines = {
            L["Frame background controls and target highlight color modes."],
            L["German, Spanish, Italian and Brazilian Portuguese locale stubs."],
        }},
        { ver = "v0.2.0", date = "2026-02", lines = {
            L["Profile system, minimap icon, target highlight, color pickers."],
        }},
        { ver = "v0.1.0", date = "2026-01", lines = {
            L["Initial release: custom boss target frames extracted from DandersFrames."],
        }},
    }

    -- Section header anchored to the previous widget (if any) so the
    -- changelog lays out under the rest of the About content instead of
    -- starting at the top of the page (which would overlap the logo).
    local header = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    if anchorWidget then
        header:SetPoint("TOPLEFT", anchorWidget, "BOTTOMLEFT", 0, -20)
    else
        header:SetPoint("TOPLEFT", 14, -10)
    end
    header:SetText("|cffeda14a" .. (L["Changelog"] or "Changelog") .. "|r")

    local divider = page:CreateTexture(nil, "OVERLAY")
    divider:SetColorTexture(0.4, 0.32, 0.2, 0.6)
    divider:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    divider:SetSize(680, 1)

    -- Anchor strategy: Y is chained to the previous widget's BOTTOM (so we
    -- flow downward), X is ALWAYS pinned to the page's LEFT (so each row
    -- gets a consistent indent regardless of what came before).
    local prev = divider
    local prevGap = -10
    for _, entry in ipairs(entries) do
        local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP",  prev, "BOTTOM", 0, prevGap)
        title:SetPoint("LEFT", page, "LEFT", 14, 0)
        title:SetJustifyH("LEFT")
        title:SetText("|cffeda14a" .. entry.ver .. "|r  |cff888888" .. entry.date .. "|r")
        prev = title
        prevGap = -4

        for _, line in ipairs(entry.lines) do
            local fs = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            fs:SetPoint("TOP",  prev, "BOTTOM", 0, prevGap)
            fs:SetPoint("LEFT", page, "LEFT", 24, 0)
            fs:SetWidth(620)
            fs:SetJustifyH("LEFT")
            fs:SetSpacing(2)
            fs:SetText("• " .. line)
            prev = fs
            prevGap = -2
        end
        prevGap = -10
    end

    local foot = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    foot:SetPoint("TOP",  prev, "BOTTOM", 0, -12)
    foot:SetPoint("LEFT", page, "LEFT", 14, 0)
    foot:SetText(L["Full GitHub history: https://github.com/Timikana/BossWatch/releases"])
end

function O.Pages.about(page)
    O.setCurrentSection(nil)  -- this page has no makeSection — widgets shouldn't register
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
        local p = O.GetPanel()
        if p then p:SetAlpha(v) end
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
        local p = O.GetPanel()
        if p then
            p:SetSize(720, 620)
            p:ClearAllPoints()
            p:SetPoint("CENTER")
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
        "|cffffff00/bossw|r — " .. L["open options"] .. "\n" ..
        "|cffffff00/bossw config|r |cff888888(" .. L["alias"] .. ")|r — " .. L["open options"] .. "\n" ..
        "|cffffff00/bossw options|r |cff888888(" .. L["alias"] .. ")|r — " .. L["open options"] .. "\n" ..
        "|cffffff00/bossw mover|r — " .. L["toggle mover"] .. "\n" ..
        "|cffffff00/bossw test N|r — " .. L["simulate N bosses (0-5)"] .. "\n" ..
        "|cffffff00/bossw test 0|r — " .. L["stop the simulation"] .. "\n" ..
        "|cffffff00/bossw reset|r — " .. L["reset all settings + reload"]
    )

    local hint = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", cmds, "BOTTOMLEFT", 0, -8)
    hint:SetText(L["Click a URL to select it, then Ctrl+C to copy."])

    -- Convention as of v0.7.5: the version history lives as a section in the
    -- About tab instead of a separate Changelog tab.
    buildChangelogSection(page, hint)
end
