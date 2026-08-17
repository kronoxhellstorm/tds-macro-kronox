# Ultimate Macro Kronox's Edition

Kronox's Edition is an analytics- and strategy-development-focused fork of **Ultimate Macro for Tower Defense Simulator**, originally created by [Darksen](https://github.com/DarksenDev/tds-macro). Darksen's original credit and GPL v3 license are retained. Big respect to Darksen since I know this macro is hell to develop and make it perfect.

## Kronox's Edition additions

* **Local Analytics** - Lifetime, per-map, per-gamemode, and per-strategy-version statistics with hourly efficiency.
* **Trustworthy Run Ledger** - Append-only run IDs, result detection evidence, and explicit unconfirmed/aborted outcomes instead of guessed losses.
* **Strategy Version Identity** - Each run records a fingerprint of the exact `.strat` contents used.
* **Strategy Reliability Rules** - Strategy-specific clone retry/defer policies and late-wave skip controls.
* **Abstract XP Tower Slots** - Record one hotbar slot as `Abstract` so the same farm strategy can place and operate any tower equipped there, with protected loadouts and extended placement retries for expensive towers.
* **Tower Evolution XP Tracker** - Read default-skin reward cards after Triumphs, maintain per-tower levels and in-level XP, report gains in the overlay/webhook, and optionally stop when selected towers reach level 20.
* **Abstract Evolution Queue** - Rotate supported Tower Evolution units through active Abstract slots, auto-equip the next batch, and stop cleanly when the queue reaches level 20.
* **Strategy Profiler** - Record per-step duration, retries, failures, and the slowest action to a local CSV without changing recorded strategy steps.
* **Modifier ROI Analytics** - Compare modifier sets by confirmed rewards per hour and surface the best supported set after enough samples exist.
* **Boost-Aware XP Analytics** - Separate base, weekend, VIP, and custom XP-boost sessions while also showing normalized base-XP efficiency.
* **Resource Budget Guard** - Protect a configurable Timescale ticket reserve/session cap and enforce optional per-run/per-session consumable limits.
* **TDS Update Canary** - Detect a changed in-game TDS version and guard its first run so a loss or watchdog recovery stops unattended looping.
* **Absolute Mode** - Optional unattended recovery that releases all input and hard-resets Roblox after a prolonged join or no-progress stall.
* **Input Failsafe** - Runtime and watchdog errors disable click/ability timers and release held keyboard or mouse input before recovery.
* **Fork-Safe Updates** - Update checks use only the Kronox Edition repository. New releases always produce an in-app notification; packaged releases can install automatically after creating a backup, while Git working copies remain notification-only.

## Original project

Ultimate Macro is an advanced, fully-featured automation tool for Roblox Tower Defense Simulator. 

## Features
* **Record & Play Custom Strategies** - Record your exact tower placements, upgrades, abilities, and actions, then replay them flawlessly.
* **Community Strategies** - Browse and download community-made `.strat` files directly within the macro.
* **Smart Game Handling** - Automatically detects game ends, checks the map, and uses the "Restart" or "Play Again" buttons to loop seamlessly.
* **Strategy Rotation** - Automatically swap between two different strategies after a set amount of runs or minutes.
* **Auto-Equip Towers** - The macro can automatically equip the required towers for your strategy before joining the match.
* **Timescale Support** - Native support for 1.5x and 2x Timescale tickets to speed up your grinds.
* **Playtime Rewards** - Automatically navigates to the lobby and collects daily/playtime rewards when available.
* **Advanced Discord Webhook** - Get real-time updates, currency stats, debug logs, and screenshots sent straight to your Discord server.
* **Multiple Upgrade Paths** - Full support for split-path towers and special towers (Pursuit, Hacker, etc.).
* **VIP Server Support** - Paste your private server link code to macro securely in your own server.

## Requirements

* **Windows** 10/11
* **AutoHotkey:** [AutoHotkey v2.0](https://www.autohotkey.com/) (Required. Do not use v1.1)
* **Windows Settings:**
  * Recommended Screen Resolution: **1920x1080**
  * Windows Scaling: **100%** (strictly required)
  * Taskbar: Must be visible (not auto-hidden)
  * **OCR Language:** The English Windows Language Pack must be installed for screen text recognition (OCR) to function properly.
* **Roblox & TDS Settings:**
  * UI Scale: **Large**
  * Screen Shake: **Disabled**
  * Prefer Vertical Upgrades: **Enabled**
  * No custom fonts
  * In-game chat must be closed
* **Conflicts:** Close all multi-client tools (like *Roblox Account Manager*) before starting, as they conflict with the macro.

## Installation

1. Download the latest release `.zip`.
2. Extract **all files** to a folder (do not run the script directly from the ZIP file).
3. Install [AutoHotkey v2.0](https://www.autohotkey.com/).
4. Run `Main.ahk`.
5. Enjoy the grind!

## Updates

The macro checks the latest release from this repository when it starts outside an active strategy run. If a newer release exists, its changelog is shown in the app.

* Releases with an attached Kronox Edition `.zip` offer a one-click update.
* Releases without a package open the GitHub release page for manual download.
* Git working copies never self-update, protecting local commits and uncommitted changes.
* Automatic updates validate the package, back up the existing installation under `%LOCALAPPDATA%\Ultimate_Macro\UpdateBackups`, and overlay the new files without deleting custom strategies.
* The release-package workflow builds and attaches the required ZIP and SHA-256 checksum. Automatic packaging can be enabled with the repository Actions variable `ENABLE_AUTOMATIC_RELEASE_PACKAGES=true`.

> **One-time updater migration:** `1.3.2a-kronox.4` still contains the inherited destructive updater. Publish `.5` without an attached ZIP and ask existing users to install it manually. After users have moved to `.5`, enable automatic release packages for later versions.

## Abstract XP tower slots

Enable **Abstract XP towers** on the Record tab and choose up to four hotbar slots before recording. New strategies save the selected slots in `abstractSlots=...` while retaining `abstractSlot=...` for compatibility with older versions. Each selected slot records with independent `Abstract1`, `Abstract2`, and later IDs, then replays against whatever tower you equip in that slot.

Abstract strategies intentionally skip Auto Equip to preserve the player's chosen XP towers. Equip the other required towers manually, put the towers you want to level in the declared slots, and then start the strategy. Abstract placements retry for up to 15 minutes so expensive towers have time to become affordable.

The bundled **Kronox's Abstract 4 Slot Farm** strategy supports one to four active abstract towers in slots 2–5. Choose the active count beside the strategy controls before starting. Inactive abstract placements are skipped before any hotbar key or click is sent, so their slots may safely remain empty. Its four placements use a wide vertical spacing and receive no upgrade actions before the original strategy continues.

## Tower Evolution XP tracking

Open **Settings > Tower XP Tracker**, enable tracking, and enter each tracked tower's current level and XP inside that level. You can leave automatic stopping off, stop when any selected target reaches level 20, or wait until all selected targets are maxed. Confirmed gains are shown in the run overlay and result webhook.

The reward reader tries both known portrait-anchor conventions and several focused/wide text crops, including the lower-row layout used by Juggernaut. If a tracked default-skin portrait is recognized but its own XP text still cannot be read, the tracker can recover it from the unambiguous shared tower-XP reward shown on the other cards from that same Triumph. Conflicting reward readings are never guessed.

> **Default skins are required.** Reward recognition uses the tower portraits shown on the Triumph screen. Any tracked tower using an alternate skin is intentionally ignored rather than risking XP being assigned to the wrong tower.

## Automation lab

The lower half of **Settings** contains the Evolution Queue, analytics context, resource guards, and update canary. The page is scrollable.

### Abstract Evolution Queue

Enter Tower Evolution names in the order you want them leveled, separated by commas. For example: `Operator, Juggernaut, Kingpin`. Semicolons are also accepted. Enable the queue and run a fixed strategy containing one or more active Abstract slots. Kronox assigns the first unfinished name to the first active Abstract slot, the next name to the second active slot, and so on. With **Auto-equip the next batch** enabled, the effective loadout is equipped automatically before the run. Once a tracked tower reaches level 20, the result watchdog removes it from the batch and assigns the next unfinished tower. It stops when the queue is complete; if automatic equipping is disabled, it stops after each reassignment so the next tower can be equipped manually.

Strategy Rotation is intentionally blocked while this queue is enabled because an Abstract slot must retain a deterministic hotbar position.

### Profiler, modifier ROI, and XP boosts

The Strategy Profiler writes append-only step telemetry to `%APPDATA%\Ultimate_Macro\strategy_profiles.csv`. It records duration, retry/error status, the strategy fingerprint, and confirmed result. The last profile summary appears in Settings and the strategy-scoped Analytics view.

Analytics now includes **By Modifiers** and **By XP Boost** scopes. Modifier rewards are compared as confirmed currency per hour; a “best” recommendation is only shown after at least three confirmed matches for a set. XP Boost views preserve the actual XP gained and calculate normalized base XP using the configured Friday/Saturday UTC weekend, VIP, and custom multipliers. Weekend and VIP bonuses use TDS's additive stacking rule.

### Resource budgets

The Timescale guard stores a remaining ticket balance, keeps the configured reserve untouched, and can cap ticket use for the current macro session. If a ticket would cross either boundary, that run continues safely at 1x.

Recorded strategies may opt into guarded item clicks with:

```ahk
UseConsumable(960, 540, "Name shown in the log")
```

The click is skipped after the configured per-run or per-session limit. Existing `Click(...)` steps are not silently reclassified as consumables.

### TDS Update Canary

The macro reads the in-game version from the bottom-right UI after joining. The first detected version establishes a baseline. When that version changes, one guarded run is marked as a canary. A confirmed Triumph verifies the version; a loss or watchdog recovery sends a warning and stops unattended looping. Use the optional version override only when OCR cannot read the version reliably.

The run overlay shows active queue assignments, boost factor, resource usage, and canary state. Detailed run context is also appended to `%APPDATA%\Ultimate_Macro\run_context.csv`.

### Absolute Mode

Absolute Mode is opt-in under **Settings > Absolute Mode / Stall Recovery**. While a strategy is marked running, it treats five minutes in a join/setup phase or ten minutes without a confirmed phase, strategy-step, wave, skip, or ability progression as a major stall. Recovery first disables every input-producing timer and releases held mouse/keyboard buttons, then closes Roblox and restarts the macro with the same active strategy. Intentional manual stops and idle UI time never trigger it. The TDS Update Canary still takes priority and may stop instead of retrying after a detected game update.

## Links & Support for Original Creator

* **Kronox Edition Repository:** [kronoxhellstorm/tds-macro-kronox](https://github.com/kronoxhellstorm/tds-macro-kronox)
* **Discord Server:** [Join for help, strategies, and updates!](https://discord.gg/DQnc2JDJtr)
* **YouTube Channel:** [@darksenn](https://www.youtube.com/@darksenn)
* **Original Repository:** [DarksenDev/tds-macro](https://github.com/DarksenDev/tds-macro)

*If you truly enjoy the macro and want to support my free work, you can donate to original creator [here](https://www.donationalerts.com/r/darksen1). Any support is massively appreciated! :sparkling_heart:*
