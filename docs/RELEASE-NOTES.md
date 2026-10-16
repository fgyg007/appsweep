# 轻卸 · AppSweep v1.0.2

## 中文

修复卸载遇到权限不足时只报错、不引导系统授权的问题。

- 普通移除使用 macOS 废纸篓服务；权限不足时交由 Finder 处理授权。密码由系统验证，轻卸不读取或保存。
- 首次使用可能出现允许轻卸控制 Finder 的自动化授权。拒绝后可到系统设置 → 隐私与安全性 → 自动化修改。
- 授权是否需要、显示密码还是其他验证方式，由 macOS 决定。完全磁盘访问等隐私权限仍需在系统设置单独授权。
- 异步等待系统操作，界面保持响应。取消后不再处理剩余项目；已完成项目仍可从历史恢复。
- 22 项自动检查通过；额外用只读目录中的临时文件验证权限失败后的 Finder 路径，移入废纸篓及恢复成功。
- 保留 v1.0.1 的容量修复及原有卸载记录格式。

下载 **AppSweep-1.0.2-arm64.dmg**，退出旧版后替换应用。运行环境：**Apple Silicon（M 系列）、macOS 14+**。界面为简体中文，验证环境为 macOS 27.0.1 / Apple Silicon，未逐一测试旧系统。

## English

Fixes permission-denied removals that previously stopped without an authorization flow.

- Uses macOS recycling, falling back to Finder on permission errors. macOS owns authentication; the app never reads or saves administrator passwords.
- First use may require Automation permission to control Finder. Change a denied permission in System Settings → Privacy & Security → Automation.
- macOS decides whether authentication is needed and which verification UI to show. Privacy permissions such as Full Disk Access remain separate.
- Asynchronous operation keeps the UI responsive. Cancellation stops remaining items; already moved items remain recoverable from history.
- All 22 automated checks pass. An additional disposable file in a read-only directory verified the permission-denied Finder fallback and successful Trash/restore round trip.
- Retains the size fix from v1.0.1 and the existing receipt format.

Download **AppSweep-1.0.2-arm64.dmg**. Quit the old app before replacing it. Requires **Apple Silicon (M-series), macOS 14+**. Simplified Chinese UI; verified on macOS 27.0.1 / Apple Silicon, not every older OS version.

## 安装与校验 / Installation and verification

Ad-hoc 签名，未 Developer ID 签名或公证，首次打开可能需要“仍要打开”。Ad-hoc signed, without Developer ID signing or notarization; Open Anyway may be required. [安装说明 / Installation guide](https://github.com/fgyg007/appsweep/blob/v1.0.2/docs/INSTALL.md).

将 SHA256SUMS.txt 与 DMG 放在同一目录 / Download both files into one directory:

```sh
shasum -a 256 -c SHA256SUMS.txt
```
