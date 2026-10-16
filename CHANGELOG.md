# Changelog / 更新记录

## 1.0.1 — 2026-10-16

- 修复应用内部符号链接导致目录遍历跳过真实文件、严重低估容量的问题。OneDrive 实测从约 135.6 MB 修正为约 1.045 GB。
- 同时修复内置扩展扫描的相同遍历问题；不跟随符号链接、不扫描链接指向的外部数据。
- 新增 framework 目录结构回归测试，覆盖容量、扩展识别与链接隔离；20 项检查通过。
- Fixed symlink handling that skipped real sibling files and severely undercounted app sizes. OneDrive now measures approximately 1.045 GB instead of 135.6 MB in the verified installation.
- Applied the same fix to embedded-extension discovery while continuing to exclude symlink targets. Added regression coverage; all 20 checks pass.
- 卸载仍是确认后移动整个已选项目到废纸篓；数据格式与系统要求不变。Trash/restore semantics, data format, and system requirements are unchanged.

## 1.0.0 — 2026-10-15

首次公开发布 / First public release.

- 拖放或选择应用，扫描常见用户级残留并显示匹配依据。
- 确认后移入废纸篓，逐项恢复记录，避免覆盖已有文件。
- 系统应用、自身、符号链接与运行中应用保护。
- 中英文文档、MIT 许可、arm64 DMG 与 SHA-256 校验。

- Drag or choose an app; review common user-level leftovers and matching reasons.
- Confirm moves to Trash and restore recorded items without overwriting files.
- Protections for system apps, the cleaner itself, symlinks, and running apps.
- Bilingual documentation, MIT license, arm64 DMG, and SHA-256 checksum.

Runtime: Apple Silicon (arm64), macOS 14+. Chinese app UI; Chinese/English documentation. Ad-hoc signed, not notarized.
运行环境：Apple Silicon（arm64）、macOS 14+。中文应用界面，中英文文档。ad-hoc 签名，未公证。
