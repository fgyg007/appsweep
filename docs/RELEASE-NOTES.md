# 轻卸 · AppSweep v1.0.1

## 中文

修复 OneDrive 等包含 framework 符号链接的应用容量被严重低估的问题。旧遍历会跳过其他真实文件，现已修正；内置扩展识别中的相同问题也已修复。

- 本机 OneDrive 实测：旧版 135,602,176 字节，新版 1,045,090,304 字节，与完整遍历一致。
- 仍不跟随符号链接，不把链接指向的外部文件算作应用数据。
- 20 项自动检查通过，包括新回归测试、精确匹配、外部链接隔离、恢复冲突及临时文件的真实废纸篓往返。
- 卸载仍是确认后移动整个已选项目到废纸篓，未改变恢复记录格式。

下载 **AppSweep-1.0.1-arm64.dmg**，退出旧版轻卸后替换 Applications 中的应用。源码 ZIP 不是安装包。

运行环境：**Apple Silicon（M 系列）、macOS 14+**。应用界面为简体中文。本次验证环境为 macOS 27.0.1 / Apple Silicon，未逐一验证旧系统。

发布包为 ad-hoc 签名，未 Apple Developer ID 签名或公证；首次打开可能需要系统“仍要打开”。[安装说明](https://github.com/fgyg007/appsweep/blob/v1.0.1/docs/INSTALL.md)。

## English

Fixes severely underestimated sizes for apps such as OneDrive containing framework symlinks. The old traversal could skip real sibling files. The same issue in embedded-extension discovery is also fixed.

- Verified OneDrive installation: 135,602,176 bytes before; 1,045,090,304 bytes after, matching a full traversal.
- Symlink targets remain excluded, including targets outside the app.
- All 20 automated checks pass, including new regression coverage, matching, link isolation, restore conflicts, and a real Trash/restore round trip with disposable fixtures.
- Confirmed removals still move entire selected items to Trash; receipt format is unchanged.

Download **AppSweep-1.0.1-arm64.dmg**. Quit the old app before replacing it in Applications. Source-code ZIPs are not installers.

Requires **Apple Silicon (M-series), macOS 14+**. The app UI is Simplified Chinese. Verified on macOS 27.0.1 / Apple Silicon, not every older OS version.

Ad-hoc signed, without Developer ID signing or notarization. macOS may require Open Anyway on first launch. [Installation guide](https://github.com/fgyg007/appsweep/blob/v1.0.1/docs/INSTALL.md).

## SHA-256

Download SHA256SUMS.txt alongside the DMG and run / 将校验文件与 DMG 放在同一目录执行：

```sh
shasum -a 256 -c SHA256SUMS.txt
```
