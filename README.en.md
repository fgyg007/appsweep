# AppSweep · 轻卸

**Review common macOS app leftovers, move selected items to Trash, and restore them when needed.**

[简体中文](README.md) · [Download DMG](https://github.com/fgyg007/appsweep/releases/latest) · [Installation](docs/INSTALL.md) · [Report an issue](https://github.com/fgyg007/appsweep/issues)

## What it does

Drag an `.app` into AppSweep or use the application picker. It lists the app bundle and related preferences, caches, and data in common locations in your user Library. Review paths, matching reasons, and estimated sizes, then confirm which items should move to the macOS Trash.

AppSweep is intended for everyday third-party desktop app removal. It has no resident background service and is not a system-wide one-click cleaner.

| Feature | Behavior |
| --- | --- |
| Drag-and-drop or picker | Accepts `.app` bundles, including bundles that still exist in Trash |
| Leftover scan | Looks in common current-user Library locations |
| Matching explanations | Distinguishes exact bundle-ID matches, directory-name matches, and sandbox data |
| Conservative defaults | Name matches and containers are unchecked; detected duplicate apps leave residual data unchecked |
| Move to Trash | Requires confirmation; never empties Trash or permanently deletes selected items |
| Restore history | Records original and Trash locations; restores without overwriting existing files |
| Basic protections | Rejects Apple system apps, itself, and symbolic-link targets; blocks removal while the target app is running |
| Local operation | No account, telemetry, upload, or internet dependency |

## System requirements

- **Apple Silicon Mac (M-series), macOS 14 Sonoma or later.**
- The DMG is **arm64 only**. Intel Macs, Windows, and Linux are not supported by this package.
- The app UI is **Simplified Chinese**; project documentation is bilingual.
- No development tools, account, internet connection, or installed background service are required.
- Deployment target: macOS 14. Verification environment: Apple Silicon / macOS 27.0.1. Not every OS version has been tested.

## Download and use

1. Download `AppSweep-1.0.0-arm64.dmg` from the [latest release](https://github.com/fgyg007/appsweep/releases/latest).
2. Open the DMG, drag `轻卸.app` to **Applications**, eject the image, and launch the installed app.
3. Quit the app you intend to uninstall, then drag its `.app` bundle into AppSweep or click `选择应用…` (Choose Application).
4. Review each candidate's path and explanation. Configuration and app data may include accounts, projects, or work history; select only what you intend to remove.
5. Click `移入废纸篓` (Move to Trash) and review the confirmation.
6. To undo, open `恢复记录` (Restore History) and click `恢复` (Restore). Existing files at the original location are never overwritten. Restoration is impossible after the relevant Trash contents are deleted.

For leftovers only, select an app bundle still present in Trash and uncheck the app bundle itself. If the bundle no longer exists, this version cannot scan solely from an app name.

**This release is ad-hoc signed, without Apple Developer ID signing or notarization.** macOS may block the first launch. Read the [installation guide](docs/INSTALL.md) to verify the source/checksum and use the system's Open Anyway flow if you trust the download.

## Scan scope

The scanner checks these directories under the current user's `~/Library/`:

- `Application Support`, `Caches`, `Preferences`
- `HTTPStorages`, `WebKit`, `Saved Application State`, `Logs`
- `Containers`, `Application Scripts` (manual selection required)

Matches use full bundle identifiers, specific suffixes, embedded extension identifiers prefixed by the main app ID, and a limited set of exact product names. There is no broad vendor-name deletion. **A matching directory name does not prove ownership**; review it before selection.

## Limitations and data handling

- Not every leftover can be found. Group Containers, hidden developer configuration, Homebrew, system services, drivers, browser extensions, Keychain items, and installer receipts are not automatically handled.
- Prefer official uninstallers for Docker, VPNs, security software, and apps with drivers or system components.
- Duplicate detection checks direct children of `/Applications`, `~/Applications`, and Desktop. Copies in custom or nested directories may be missed.
- Unknown background processes and shared data cannot be fully identified. A bundle-ID match does not prove that no other tool uses the data.
- Permission failures are reported. AppSweep does not elevate privileges or bypass protections. Size estimates may exclude unreadable directories.
- A restore receipt is saved after each move. If the process is interrupted between a move and receipt persistence, manual recovery from Finder's Trash may be needed.
- Moving files to Trash does not immediately reclaim disk space. AppSweep never empties Trash automatically.

Restore receipts live in `~/Library/Application Support/io.jlmac.AppSweep/History/`. They contain file paths for operations performed by AppSweep, remain local, and are not backups. They do not import removals done by other tools. Remove private paths before including diagnostic information in an issue.

## Build and verification

```sh
git clone https://github.com/fgyg007/appsweep.git
cd appsweep
zsh scripts/test.sh
zsh scripts/build.sh
zsh scripts/package.sh
```

See [development notes](docs/DEVELOPMENT.md). There are no third-party Swift packages. Tests cover exact/name matching, shared-data isolation, symlinks, duplicate apps, system-app rejection, failed moves, restore conflicts, and a real macOS Trash/restore round trip using disposable fixtures. They do not uninstall real apps.

Core file handling, compilation, and signatures have been checked. Automated coverage of drag-and-drop, every UI interaction, and all OS versions remains incomplete.

## License

[MIT](LICENSE). Issues and focused pull requests are welcome. Companion app: [ClipDay · 轻贴](https://github.com/fgyg007/clipday), a 24-hour clipboard history with direct paste.
