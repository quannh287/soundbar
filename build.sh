#!/bin/sh
set -e
APP=SoundBar.app
# --disable-sandbox and a local cache: Homebrew builds inside a sandbox that denies
# SwiftPM its usual cache locations, and the formula runs this script verbatim.
swift build -c release --disable-sandbox --cache-path .build/cache
# Keeps the documented `./soundbar --list` smoke check working.
cp .build/release/focusbar soundbar
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp soundbar "$APP/Contents/MacOS/SoundBar"
cp AppIcon.icns "$APP/Contents/Resources/"
# LSUIElement keeps it out of the Dock; the bundle is also what SMAppService registers.
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>SoundBar</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIdentifier</key><string>local.soundbar</string>
  <key>CFBundleName</key><string>SoundBar</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>CFBundleURLTypes</key><array><dict>
    <key>CFBundleURLName</key><string>local.soundbar</string>
    <key>CFBundleURLSchemes</key><array><string>soundbar</string></array>
  </dict></array>
</dict></plist>
PLIST
codesign -s - --force --deep "$APP"
echo "built $APP"
