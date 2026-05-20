#!/bin/bash
# -----------------------------------------------------------------------------
# Swiftfin tvOS 7-Day Refresh & Deploy Script
# This script compiles the latest tvOSPlayer build and installs it wirelessly
# onto your "Living Room" Apple TV, renewing the 7-day developer certificate.
# -----------------------------------------------------------------------------

# Exit on any error
set -e

# Config
PROJECT_DIR="/Users/rushikeshpatil/dev/general/Swiftfin-tvOS"
APPLE_TV_ID="00008110-000C054001E1401E"
SCHEME="Swiftfin tvOS"
CONFIG="Debug"
TIMESTAMP_FILE="$PROJECT_DIR/Scripts/last_refresh_timestamp.log"

# Smart Check: Only run if last successful refresh was >= 6 days ago
CURRENT_TIME=$(date +%s)
THRESHOLD_DAYS=6
THRESHOLD_SECONDS=$((THRESHOLD_DAYS * 24 * 60 * 60))

if [ -f "$TIMESTAMP_FILE" ]; then
  LAST_REFRESH=$(cat "$TIMESTAMP_FILE")
  # Ensure LAST_REFRESH is a valid number
  if [[ "$LAST_REFRESH" =~ ^[0-9]+$ ]]; then
    ELAPSED=$((CURRENT_TIME - LAST_REFRESH))
    if [ $ELAPSED -lt $THRESHOLD_SECONDS ]; then
      REMAINING_DAYS=$(( (THRESHOLD_SECONDS - ELAPSED) / 86400 + 1 ))
      echo "⏳ Apple TV refresh skipped. Last refresh was $((ELAPSED / 86400)) days ago. Next refresh scheduled in $REMAINING_DAYS day(s)."
      exit 0
    fi
  fi
fi

echo "🚀 [1/3] Navigating to Swiftfin directory..."
cd "$PROJECT_DIR"

echo "🧹 [2/3] Compiling Swiftfin tvOS app programmatically..."
# Build the scheme for the Apple TV destination
xcodebuild build \
  -scheme "$SCHEME" \
  -destination "id=$APPLE_TV_ID" \
  -configuration "$CONFIG" \
  -quiet

# Locate the compiled .app bundle in DerivedData
echo "🔍 Finding compiled .app bundle..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Swiftfin tvOS.app" -path "*/Build/Products/Debug-appletvos/Swiftfin tvOS.app" ! -path "*/Index.noindex/*" | head -n 1)

if [ -z "$APP_PATH" ]; then
  echo "❌ Error: Could not locate 'Swiftfin tvOS.app' in DerivedData."
  exit 1
fi

echo "📦 Found compiled app at: $APP_PATH"

echo "📲 [3/3] Wirelessly deploying to Living Room Apple TV ($APPLE_TV_ID)..."
xcrun devicectl device install app --device "$APPLE_TV_ID" "$APP_PATH"

echo "🎉 Success! The 7-day developer certificate has been refreshed and deployed!"

# Save current timestamp on success
echo "$CURRENT_TIME" > "$TIMESTAMP_FILE"
