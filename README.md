# Ultimate Macro Kronox's Edition

Kronox's Edition is an analytics- and strategy-development-focused fork of **Ultimate Macro for Tower Defense Simulator**, originally created by [Darksen](https://github.com/DarksenDev/tds-macro). Darksen's original credit and GPL v3 license are retained.

## Kronox's Edition additions

* **Local Analytics** - Lifetime, per-map, per-gamemode, and per-strategy-version statistics with hourly efficiency.
* **Trustworthy Run Ledger** - Append-only run IDs, result detection evidence, and explicit unconfirmed/aborted outcomes instead of guessed losses.
* **Strategy Version Identity** - Each run records a fingerprint of the exact `.strat` contents used.
* **Strategy Reliability Rules** - Strategy-specific clone retry/defer policies and late-wave skip controls.
* **Abstract XP Tower Slots** - Record one hotbar slot as `Abstract` so the same farm strategy can place and operate any tower equipped there, with protected loadouts and extended placement retries for expensive towers.
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

Enable **Abstract XP tower** on the Record tab and choose a hotbar slot before recording. The saved strategy writes `abstractSlot=1..5`, records that slot with `Abstract` tower IDs, and replays every placement, upgrade, and sell action against whatever tower you equip in that slot.

Abstract strategies intentionally skip Auto Equip to preserve the player's chosen XP tower. Equip the other required towers manually, put the tower you want to level in the declared slot, and then start the strategy. Abstract placements retry for up to 15 minutes so expensive towers have time to become affordable.

## Links & Support for Original Creator

* **Kronox Edition Repository:** [kronoxhellstorm/tds-macro-kronox](https://github.com/kronoxhellstorm/tds-macro-kronox)
* **Discord Server:** [Join for help, strategies, and updates!](https://discord.gg/DQnc2JDJtr)
* **YouTube Channel:** [@darksenn](https://www.youtube.com/@darksenn)
* **Original Repository:** [DarksenDev/tds-macro](https://github.com/DarksenDev/tds-macro)

*If you truly enjoy the macro and want to support my free work, you can donate to original creator [here](https://www.donationalerts.com/r/darksen1). Any support is massively appreciated! :sparkling_heart:*
