# Changelog (English mirror)

This file is the English mirror of `CHANGELOG.md`. Every release MUST update
both files. The Discord release notifier (`scripts/_post_discord.py`) posts
one webhook message per language (FR + EN) — convention strictly enforced on
the *Watch addon family Discord.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning per [SemVer](https://semver.org/).

## [Unreleased]

## [0.8.3] - 2026-06-17

### Removed
- **`Frames/MyAuras.lua` (combat-log tracker) removed.** Introduced in v0.8.0 to make the Auras "Only mine" filter reliable on Retail Midnight 12.0+, it turned out to be unusable on that client: Blizzard now rejects `RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")` with `ADDON_ACTION_FORBIDDEN` as soon as any tainted frame is on the caller's stack — which happens constantly when other addons (ElvUI/DBM/Auctionator…) are loaded. Successive workarounds (`C_Timer.After`, exponential backoff, `IsEventRegistered` verification) all failed.
- Result: the **Auras → Source → "Only mine"** filter reverts to its v0.7.x behaviour. It works perfectly on **Classic / SoD / TBC Anniversary**, and is **partially reliable on Retail Midnight** (Blizzard secret-tags `isFromPlayerOrPlayerPet` on hostile-unit auras — no boss-frame addon has a clean workaround right now).

### Fixed
- **`ADDON_ACTION_FORBIDDEN` spam still present in v0.8.2** (Klav reported 6+ occurrences on 12.0.7). Cause = `Frames/MyAuras.lua`, removed above. (reported by Klav / warcraftiiitft on 12.0.7). Deferring past `PLAYER_LOGIN` wasn't enough — `BossWatch.lua` has its own `PLAYER_LOGIN` handler that builds SecureUnitButton frames and taints the Lua thread, so `MyAuras.lua`'s `RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")` still landed inside an execution flagged as protected. Robust fix: escape the current thread via `C_Timer.After(0, ...)`, which reschedules the registration onto the next frame tick in a fresh context.

## [0.8.2] - 2026-06-17

### Fixed
- **Boss name + HP text disappearing when the boss has no absorb shield** (reported by warcraftiiitft, Frost DK 12.0.7). v0.8.0 reparented `nameText` and `healthText` to the absorb StatusBar so they'd render above the shield, but when `absorbBar:Hide()` ran (most pulls), the child FontStrings inherited the hidden state and vanished. Text now lives on a dedicated `textOverlay` frame parented to the HP bar (always visible) with a frame level one above the absorb bar — visible when there's no shield AND above when there is one.

## [0.8.1] - 2026-06-17

### Fixed
- **`ADDON_ACTION_FORBIDDEN` error spam on Retail Midnight 12.0+** (reported by Smuglerz). Registering `COMBAT_LOG_EVENT_UNFILTERED` at file-load main chunk in the new `Frames/MyAuras.lua` module (v0.8.0) hit Blizzard's protected-function trap, producing 20+ errors at login. Registration is now deferred until after `PLAYER_LOGIN`, the same pattern WeakAuras / BigWigs use. The "Only mine" filter still works identically — just after the login tick.

## [0.8.0] - 2026-06-16

### Added
- **Classic Era / Season of Discovery support.** A third TOC (`BossWatch-Vanilla.toc`, Interface 11507) now installs the addon on the Vanilla 1.15.x client. On that client the `boss1..5` unit IDs don't exist (they were introduced in Cataclysm) — BossWatch instead detects hostile elites / world bosses / rare elites by scanning your target, mouseover and visible enemy nameplates (`UnitClassification`), and assigns them dynamically to the frames. **Enable enemy nameplates (Ctrl-V)** for auto-detection to work. Stable slot IDs (no visual jumping when adds die), configurable capacity (3 / 5 / 8 frames).
- **TBC Anniversary support** (Interface 20504–20506) via a fourth TOC that loads the same detection engine.
- **New "Classic / SoD" tab** in the options panel, visible only on clients without native `boss1..5` (Vanilla, SoD, TBC Anniversary).
- **Reliable "Only mine" aura filter on Retail Midnight 12.0+** thanks to combat-log tracking (`Frames/MyAuras.lua`) that bypasses the secret-tagging of `isFromPlayerOrPlayerPet` on hostile-unit auras.
- Minimap icon **on by default** + command list printed at login.

### Fixed
- Boss name / HP text now render **above** the absorb shield instead of getting hidden underneath when the shield grows past ~25% of the bar (benefits every client).

### Internal
- New `BossW.SlotProvider` abstraction layer between BossFrames and unit tokens. On Retail / Midnight / MoP Classic the trivial provider returns `"boss"..i` — behaviour is bit-for-bit identical to before. On Vanilla / SoD / TBC an override provider manages virtual slots. Lets us support new clients without forking `Frames/Boss.lua`.
