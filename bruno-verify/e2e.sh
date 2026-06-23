#!/usr/bin/env bash
# Track B — real end-to-end on the sim, fully autonomous (no UI typing).
# Fresh install → headless auto-sign-in (BRUNO_AUTOSIGNIN, creds via env) → screenshot the
# real-library Home → relaunch (no auto-sign-in) to prove the ad-hoc signing persists the
# keychain token across launches → crash check. Creds come from bruno_jellyfin.env (gitignored).
set -uo pipefail

OUT="${1:-$HOME/Desktop}"
BUNDLE="com.diplomacymusic.bruno"
REPO="/Users/danielbrunelle/Documents/Claude/Projects/bruno"
set -a; source "$REPO/bruno_jellyfin.env"; set +a

DEV="$(xcrun simctl list devices booted | grep -m1 -oE '[0-9A-F-]{36}')"
[ -z "$DEV" ] && { echo "no booted sim"; exit 1; }
APP="$(find ~/Library/Developer/Xcode/DerivedData/Swiftfin-*/Build/Products/Debug-appletvsimulator -maxdepth 1 -name '*.app' | head -1)"
echo "device=$DEV"; echo "app=$APP"

alive() { xcrun simctl spawn "$DEV" launchctl list 2>/dev/null | grep -qi "diplomacymusic.bruno"; }
pull_log() {
  local c; c="$(xcrun simctl get_app_container "$DEV" "$BUNDLE" data 2>/dev/null)"
  [ -n "$c" ] && cat "$c/Documents/bruno-autosignin.log" 2>/dev/null
}

echo "=== fresh install ==="
xcrun simctl terminate "$DEV" "$BUNDLE" 2>/dev/null
xcrun simctl uninstall "$DEV" "$BUNDLE" 2>/dev/null
xcrun simctl install "$DEV" "$APP"

echo "=== launch with headless auto-sign-in ==="
SIMCTL_CHILD_BRUNO_AUTOSIGNIN=1 \
SIMCTL_CHILD_JF_BASE="$JF_BASE" \
SIMCTL_CHILD_JF_USER_NAME="$JF_USER_NAME" \
SIMCTL_CHILD_JF_PASS="$JF_PASS" \
  xcrun simctl launch "$DEV" "$BUNDLE" >/dev/null
sleep 16
echo "--- autosignin log ---"; pull_log
if alive; then echo "process: ALIVE after sign-in"; else echo "process: GONE (crash) after sign-in"; fi
xcrun simctl io "$DEV" screenshot "$OUT/bruno-real-home.png" && echo "shot: $OUT/bruno-real-home.png"

echo "=== relaunch (no auto-sign-in) — tests keychain persistence ==="
xcrun simctl terminate "$DEV" "$BUNDLE" 2>/dev/null
sleep 2
xcrun simctl launch "$DEV" "$BUNDLE" >/dev/null
sleep 12
if alive; then echo "process: ALIVE after relaunch — KEYCHAIN PERSISTED"; else echo "process: GONE (crash) after relaunch — keychain NOT persisted"; fi
xcrun simctl io "$DEV" screenshot "$OUT/bruno-real-home-relaunch.png" && echo "shot: $OUT/bruno-real-home-relaunch.png"

echo "=== newest crash report (if any) ==="
ls -t ~/Library/Logs/DiagnosticReports/"Swiftfin tvOS"*.ips 2>/dev/null | head -1
