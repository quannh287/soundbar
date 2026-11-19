#!/bin/sh
set -e
APP=SoundBar.app
swiftc -O -parse-as-library main.swift -o soundbar
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp soundbar "$APP/Contents/MacOS/SoundBar"
cp AppIcon.icns "$APP/Contents/Resources/"
# LSUIElement keeps it out of the Dock; MenuBarExtra needs a real bundle to read it.
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
</dict></plist>
PLIST
codesign -s - --force --deep "$APP"
echo "built $APP"
