#!/bin/bash
# Build PasteToFile.app (with embedded Finder Sync extension) as a universal
# binary, ad-hoc sign it, install to ~/Applications, and register + enable it.
#   ./build.sh               build and install
#   ./build.sh --no-install  build only, into ./build
set -euo pipefail
cd "$(dirname "$0")"

APP=build/PasteToFile.app
APPEX="$APP/Contents/PlugIns/PasteToFileFinderSync.appex"
EXT_ID=com.cabird.PasteToFile.FinderSync
DEST="$HOME/Applications/PasteToFile.app"
SDK="$(xcrun --show-sdk-path --sdk macosx)"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

# compile <output> <swiftc args...>: builds arm64 + x86_64 and lipos them.
compile() {
  local out=$1; shift
  for arch in arm64 x86_64; do
    xcrun swiftc -O -sdk "$SDK" -target "$arch-apple-macos13.0" "$@" -o "build/obj/$(basename "$out").$arch"
  done
  lipo -create "build/obj/$(basename "$out")".{arm64,x86_64} -output "$out"
}

rm -rf build
mkdir -p build/obj "$APP/Contents/MacOS" "$APPEX/Contents/MacOS"

# Extension: an app extension binary whose entry point is NSExtensionMain.
compile "$APPEX/Contents/MacOS/PasteToFileFinderSync" \
  -application-extension -module-name PasteToFileFinderSync \
  -Xlinker -e -Xlinker _NSExtensionMain Extension/*.swift
cp Extension/Info.plist "$APPEX/Contents/Info.plist"

# Host app.
compile "$APP/Contents/MacOS/PasteToFile" App/main.swift
cp App/Info.plist "$APP/Contents/Info.plist"

# Sign inside-out (ad-hoc; no developer identity needed for local use).
codesign --force --sign - --entitlements Extension/entitlements.plist "$APPEX"
codesign --force --sign - "$APP"

[[ "${1:-}" == "--no-install" ]] && { echo "Built $APP"; exit 0; }

# Keep LaunchServices from picking up the build copy instead of the installed one.
"$LSREGISTER" -u "$PWD/$APP" 2>/dev/null || true

mkdir -p "$HOME/Applications"
rm -rf "$DEST"
cp -R "$APP" "$DEST"

# pkd registers asynchronously (and slowly right after the old copy is
# removed), so retry register + enable until it reports enabled ("+").
enabled=0
for _ in {1..30}; do
  pluginkit -a "$DEST/Contents/PlugIns/PasteToFileFinderSync.appex" || true
  pluginkit -e use -i "$EXT_ID" 2>/dev/null || true
  status="$(pluginkit -m -A -i "$EXT_ID" 2>/dev/null || true)"
  if [[ "$status" == +* ]]; then enabled=1; break; fi
  sleep 1
done
if (( ! enabled )); then
  echo "error: extension did not register/enable; run ./build.sh again" >&2
  exit 1
fi

killall Finder 2>/dev/null || true   # Finder relaunches and loads the extension
echo "Installed $DEST"
pluginkit -m -A -v -i "$EXT_ID"
