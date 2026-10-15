#!/bin/zsh
set -eu
cd "${0:A:h:h}"
APP="$PWD/build/轻卸.app"
source scripts/swift-env.sh
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc "${SWIFT_FLAGS[@]}" -O -target arm64-apple-macosx14.0 Sources/Core.swift Sources/App.swift -o "$APP/Contents/MacOS/AppSweep" -framework SwiftUI -framework AppKit
xcrun swiftc "${SWIFT_FLAGS[@]}" scripts/Icon.swift -o build/make-icon -framework AppKit
build/make-icon "$PWD/build/AppIcon.iconset"
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>AppSweep</string>
<key>CFBundleIdentifier</key><string>io.jlmac.AppSweep</string>
<key>CFBundleName</key><string>轻卸</string>
<key>CFBundleDisplayName</key><string>轻卸</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
echo "$APP"
