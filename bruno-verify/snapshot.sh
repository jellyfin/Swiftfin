#!/usr/bin/env bash
# Track A — render the Bruno GUI from mock data (no server / no sign-in / no keychain).
# Installs the signed sim build, launches it in BRUNO_SNAPSHOT mode for each surface,
# and captures a PNG per surface. Usage: ./bruno-verify/snapshot.sh
set -euo pipefail

OUT="${1:-$HOME/Desktop}"
BUNDLE="com.diplomacymusic.bruno"
DEV="$(xcrun simctl list devices booted | grep -m1 -oE '[0-9A-F-]{36}')"
[ -z "$DEV" ] && { echo "no booted sim"; exit 1; }
APP="$(find ~/Library/Developer/Xcode/DerivedData/Swiftfin-*/Build/Products/Debug-appletvsimulator -maxdepth 1 -name '*.app' | head -1)"
echo "device=$DEV"
echo "app=$APP"

xcrun simctl terminate "$DEV" "$BUNDLE" 2>/dev/null || true
xcrun simctl uninstall "$DEV" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$DEV" "$APP"

shoot() {
  local view="$1" file="$2"
  xcrun simctl terminate "$DEV" "$BUNDLE" 2>/dev/null || true
  SIMCTL_CHILD_BRUNO_SNAPSHOT=1 SIMCTL_CHILD_BRUNO_SNAPSHOT_VIEW="$view" \
    xcrun simctl launch "$DEV" "$BUNDLE" >/dev/null
  sleep 6
  xcrun simctl io "$DEV" screenshot "$OUT/$file"
  echo "captured $OUT/$file (view=$view)"
}

shoot home  bruno-home.png
shoot hero  bruno-hero.png
shoot shelf bruno-shelves.png
