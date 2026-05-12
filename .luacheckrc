-- luacheck config for BossWatch
-- Run locally: `luacheck .` (or via the CI workflow at .github/workflows/lint.yml)

std = "lua51"

-- Ignore the bundled third-party libraries — they have their own style.
exclude_files = {
    "Libs/",
}

-- WoW globals we read or call. Not exhaustive — extend as needed when a
-- new lint failure mentions a missing global. Sourced from
-- https://warcraft.wiki.gg/wiki/Lua_API and observed usage.
read_globals = {
    -- Frame / templates
    "CreateFrame", "UIParent", "GameTooltip", "GameFontNormal", "GameFontNormalLarge",
    "GameFontNormalSmall", "GameFontHighlight", "GameFontHighlightSmall",
    "GameFontDisableSmall", "NumberFontNormalSmall",

    -- Standard widget
    "BackdropTemplate", "PortraitFrameTemplate", "PanelTabButtonTemplate",
    "UICheckButtonTemplate", "UIPanelButtonTemplate", "UIPanelScrollFrameTemplate",
    "WowStyle1DropdownTemplate", "MinimalSliderWithSteppersTemplate",
    "InputBoxTemplate", "SecureUnitButtonTemplate", "CooldownFrameTemplate",
    "BasicFrameTemplateWithInset",

    -- Unit / aura APIs
    "UnitExists", "UnitName", "UnitClass", "UnitHealth", "UnitHealthMax",
    "UnitHealthPercent", "UnitPower", "UnitPowerMax", "UnitPowerType",
    "UnitIsUnit", "UnitIsDeadOrGhost", "UnitReaction", "UnitChannelInfo",
    "UnitCastingInfo", "UnitAura", "UnitGetTotalAbsorbs", "GetUnitName",
    "UnitGroupRolesAssigned", "UnitIsGroupLeader", "UnitIsGroupAssistant",
    "C_UnitAuras", "AuraUtil", "Enum",

    -- Raid / group
    "GetNumGroupMembers", "GetRaidRosterInfo", "IsInRaid", "IsInGroup",
    "SetRaidSubgroup", "GetRaidTargetIndex", "SetRaidTarget",
    "SetRaidTargetIconTexCoord", "SetRaidTargetIconTexture",

    -- State driver / events / state
    "RegisterStateDriver", "InCombatLockdown", "ReloadUI", "GetLocale",
    "GetBuildInfo", "GetTime", "GetRealmName",

    -- Constants / tables / power
    "WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE", "WOW_PROJECT_MISTS_CLASSIC",
    "RAID_CLASS_COLORS", "FACTION_BAR_COLORS", "PowerBarColor", "CurveConstants",
    "SetPortraitTexture", "STANDARD_TEXT_FONT", "CreateColor",
    "AbbreviateLargeNumbers", "C_AddOns",

    -- Lib helpers (we read these dynamically)
    "LibStub",

    -- Slash command system
    "SLASH_BOSSWATCH1", "SLASH_BOSSWATCH2", "SLASH_TANKWATCH1", "SLASH_TANKWATCH2",
    "SlashCmdList", "issecretvalue",

    -- Misc legacy
    "setfenv", "loadstring", "wipe", "format",
    "ChatFontNormal", "Settings", "StaticPopupDialogs", "StaticPopup_Show",
    "PanelTemplates_SelectTab", "PanelTemplates_DeselectTab",
    "PanelTemplates_TabResize",
    "InterfaceOptions_AddCategory",
    "PlaySound", "SOUNDKIT",
    "C_Timer",

    -- WoW UI mixins / widget classes
    "MinimalSliderWithSteppersMixin", "ColorPickerFrame", "OpacitySliderFrame",

    -- Localized constants exposed as globals by Blizzard FrameXML
    "ACCEPT", "CANCEL", "YES", "NO",
}

-- Globals we write (typically SavedVariables and namespace).
globals = {
    "BossWatchDB",
    "_BuildChangelogSection",   -- forward-declared helper inside Panel.lua
    "BossWatchOptions",         -- name of the panel frame, used by /dump
    "BossWatchContainer",
    "BossWatchFrame1", "BossWatchFrame2", "BossWatchFrame3",
    "BossWatchFrame4", "BossWatchFrame5",
}

-- Style — we keep it lenient. Many of these are intentional WoW addon
-- patterns (caching globals as locals for perf, ignoring callback args,
-- standard `addonName, AddonTable = ...` boilerplate, etc.).
ignore = {
    "111",       -- setting non-standard global variable (SLASH_*, etc.)
    "112",       -- mutating non-standard global variable
    "113",       -- accessing undefined global (we whitelist explicitly)
    "121",       -- setting read-only global (Blizzard's globals are "read-only" per std)
    "122",       -- setting read-only field of global (e.g. SlashCmdList["BOSSWATCH"])
    "211",       -- unused variable (typically `local UnitExists = UnitExists` perf cache)
    "212/self",  -- unused argument 'self' (common in addon callbacks)
    "212/_.*",   -- unused argument starting with underscore (intentional)
    "213",       -- unused loop variable (common with `_, v in pairs`)
    "311",       -- value assigned to variable is unused
    "542",       -- empty if branch (common in defensive coding)
    "631",       -- line is too long — many user-facing string lines
}

-- Per-file overrides
files["BossWatch.lua"] = {
    -- The codec functions are reused from a third-party snippet, leave alone.
    ignore = { "611", "612", "613", "614" },  -- trailing whitespace variants
}
