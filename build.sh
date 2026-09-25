#!/bin/bash
# Build PasteToFile.app (with embedded Finder Sync extension), ad-hoc sign it,
# install to ~/Applications, and register + enable the extension.
set -euo pipefail
cd "$(dirname "$0")"

APP=build/PasteToFile.app
APPEX="$APP/Contents/PlugIns/PasteToFileFinderSync.appex"
EXT_ID=com.cabird.PasteToFile.FinderSync
DEST="$HOME/Applications/PasteToFile.app"
FLAGS=(-O -target "$(uname -m)-apple-macos13.0" -sdk "$(xcrun --show-sdk-path --sdk macosx)")

rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APPEX/Contents/MacOS"

# Extension: an app extension binary whose entry point is NSExtensionMain.
xcrun swiftc "${FLAGS[@]}" -application-extension -module-name PasteToFileFinderSync \
  -Xlinker -e -Xlinker _NSExtensionMain \
  Extension/*.swift -o "$APPEX/Contents/MacOS/PasteToFileFinderSync"
cp Extension/Info.plist "$APPEX/Contents/Info.plist"

# Host app.
xcrun swiftc "${FLAGS[@]}" App/main.swift -o "$APP/Contents/MacOS/PasteToFile"
cp App/Info.plist "$APP/Contents/Info.plist"

# Sign inside-out (ad-hoc; no developer identity needed for local use).
codesign --force --sign - --entitlements Extension/entitlements.plist "$APPEX"
codesign --force --sign - "$APP"

# Install and register.
if [[ "${1:-}" != "--no-install" ]]; then
  mkdir -p "$HOME/Applications"
  rm -rf "$DEST"
  cp -R "$APP" "$DEST"
  # pkd registers asynchronously (and slowly right after the old copy is
  # removed), so retry register + enable until it reports enabled ("+").
  for _ in {1..30}; do
    pluginkit -a "$DEST/Contents/PlugIns/PasteToFileFinderSync.appex"
    pluginkit -e use -i "$EXT_ID" 2>/dev/null || true
    pluginkit -m -A -i "$EXT_ID" | grep -q '^+' && break
    sleep 1
  done
  killall Finder 2>/dev/null || true   # Finder relaunches and loads the extension
  echo "Installed $DEST"
  pluginkit -m -A -v -i "$EXT_ID"
fi
