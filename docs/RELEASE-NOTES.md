# 轻卸 · AppSweep v1.0.0

## 中文

首次开源发布，MIT 许可。

- 拖放或选择应用，扫描常见用户级残留并显示匹配依据。
- 确认后移入废纸篓，逐项恢复记录，避免覆盖已有文件。
- 系统应用、自身、符号链接与运行中应用保护。
- 中英文文档、MIT 许可、arm64 DMG 与 SHA-256 校验。

**下载：`AppSweep-1.0.0-arm64.dmg`。** 自动生成的 Source code ZIP/TAR 是源码，不是安装包。

**运行环境：Apple Silicon（M 系列，arm64），macOS 14 Sonoma 或更新。**不支持 Intel。本次实际验证在 macOS 27.0.1 / Apple Silicon 完成，未覆盖所有旧版本。应用界面为简体中文。

打开 DMG，把 `轻卸.app` 拖到 Applications，推出映像后运行。发布包采用 ad-hoc 签名，**没有 Apple Developer ID 签名或公证**；首次启动可能需要系统设置中的“仍要打开”。

[中文介绍](https://github.com/fgyg007/appsweep#readme) · [安装、权限与校验说明](https://github.com/fgyg007/appsweep/blob/v1.0.0/docs/INSTALL.md)

## English

First public release under the MIT license.

- Drag or choose an app; review common user-level leftovers and matching reasons.
- Confirm moves to Trash and restore recorded items without overwriting files.
- Protections for system apps, the cleaner itself, symlinks, and running apps.
- Bilingual documentation, MIT license, arm64 DMG, and SHA-256 checksum.

**Download: `AppSweep-1.0.0-arm64.dmg`.** The auto-generated Source code ZIP/TAR files are not installers.

**Requires Apple Silicon (M-series, arm64), macOS 14 Sonoma or later.** Intel Macs are not supported by this package. Runtime verification was performed on macOS 27.0.1 / Apple Silicon, not every older OS version. The app UI is Simplified Chinese.

Open the DMG, drag `轻卸.app` to Applications, eject the image, and launch the installed app. This release is **ad-hoc signed, without Developer ID signing or Apple notarization**. macOS may require the Open Anyway flow on first launch.

[English overview](https://github.com/fgyg007/appsweep/blob/v1.0.0/README.en.md) · [Installation and checksums](https://github.com/fgyg007/appsweep/blob/v1.0.0/docs/INSTALL.md)

## SHA-256

Download `SHA256SUMS.txt` alongside the DMG, then run / 将校验文件与 DMG 放在同一目录，执行：

```sh
shasum -a 256 -c SHA256SUMS.txt
```
