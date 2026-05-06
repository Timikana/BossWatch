<div align="center">
  <img src="logo.png" alt="BossWatch logo" width="220">

  # BossWatch

  **Modern, fully configurable boss frames for WoW Retail / Midnight 12.0.**

  [![CurseForge](https://img.shields.io/badge/CurseForge-BossWatch-f16436)](https://www.curseforge.com/wow/addons/bosswatch)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
  ![WoW Version](https://img.shields.io/badge/WoW-12.0%20Midnight-blue)
</div>

---

## What it does

BossWatch replaces Blizzard's default boss target frames with a custom replacement built for the modern Retail UI. Pick your textures, your fonts, position the raid markers, configure auras the way you want — everything is exposed in a clean tabbed options panel with live preview.

## Features

- **Custom boss frames** with portrait, health & power bars, integrated cast bar and auras
- **LSM-powered textures** — bundles modern Blizzard textures (`Blizzard Raid Bar`, `Blizzard Modern`) and supports any LibSharedMedia statusbar
- **Custom fonts** — pick any LSM font, set size and outline globally
- **Cast bar** with spell name, icon, optional detached layout
- **Aura tracking** with Blizzard-style or boss-only filter, stacks, cooldown swipe and timer
- **Raid target icon** overlay on each frame, freely positioned
- **Tabbed options panel** with live preview — also accessible from `ESC → Options → AddOns → BossWatch`
- Built-in **test mode** (1 to 5 fake bosses) to preview your config out of combat
- **Combat-safe** — secure frame layout changes are deferred until out of combat
- Handles WoW Midnight **secret unit values** (HP/Power/cast info on hostile units)

## Installation

### CurseForge / Wago / WoWUp
Search for **BossWatch** in your addon manager and click install.

### Manual
1. Download the latest release from the [Releases page](https://github.com/Timikana/BossWatch/releases)
2. Extract the `BossWatch` folder into `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or `/reload`

## Slash commands

| Command | Description |
|---|---|
| `/bw` | Open the options panel |
| `/bw mover` | Toggle the drag handle to reposition the boss container |
| `/bw test N` | Simulate N bosses (0 to 5) with HP drain, casts and auras |
| `/bw reset` | Wipe all settings and reload the UI |

## Configuration

Open the options with `/bw`. Tabs:

- **Layout** — anchor, size, spacing, scale, portrait position
- **Bars** — health/power textures, color mode, background alphas
- **Cast Bar** — texture, icon position, detached layout
- **Text** — name and HP/power text positioning, format, plus a global font selector
- **Raid Marker** — position the raid target icon (skull, cross, star…) on each frame
- **Auras** — filter (debuffs / buffs), source (boss-cast only by default), max count, size, anchoring, timer placement
- **About** — version, GitHub links

## Localization

| Locale | Status |
|---|---|
| English (`enUS`) | ✓ Complete |
| French (`frFR`) | ✓ Complete |

Want to contribute another locale? Copy `Locales/frFR.lua`, change the `GetLocale()` check, translate the values, and open a PR.

## Bundled libraries

- [LibStub](https://www.wowace.com/projects/libstub)
- [CallbackHandler-1.0](https://www.wowace.com/projects/callbackhandler)
- [LibSharedMedia-3.0](https://www.wowace.com/projects/libsharedmedia-3-0)

## Issues & feedback

Found a bug or want to suggest a feature? Open an issue on the [issue tracker](https://github.com/Timikana/BossWatch/issues).

## License

[MIT](LICENSE) — feel free to fork, modify, and contribute back.

---

<div align="center">
  Made with ❤ for the WoW Midnight community.
</div>
