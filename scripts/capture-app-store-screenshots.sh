#!/bin/bash
# Build, seed demo data, and capture all three App Store screenshots.
# Run from repo root: ./scripts/capture-app-store-screenshots.sh
# No Cursor approval needed when run in your terminal.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCREENSHOTS_DIR="$REPO_ROOT/screenshots"
BUNDLE_ID="com.timwood.vgb"
SIM_ID="${1:-booted}"   # optional: device id or "booted"

cd "$REPO_ROOT"

# Build
echo "Building VGB for simulator..."
xcodebuild -scheme VGB -destination 'platform=iOS Simulator,name=iPhone 16e' -configuration Debug build -quiet 2>/dev/null || \
xcodebuild -scheme VGB -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build -quiet 2>/dev/null || \
xcodebuild -scheme VGB -destination 'platform=iOS Simulator,name=iPhone 16e' -configuration Debug build

APP=$(find ~/Library/Developer/Xcode/DerivedData -name "VGB.app" -type d -path "*Build/Products*" -not -path "*Index*" 2>/dev/null | head -1)
if [[ -z "$APP" ]]; then
  echo "VGB.app not found in DerivedData"
  exit 1
fi

# Use booted or specific device
if [[ "$SIM_ID" != "booted" ]]; then
  xcrun simctl boot "$SIM_ID" 2>/dev/null || true
  DEVICE="$SIM_ID"
else
  DEVICE="booted"
fi

echo "Installing app..."
xcrun simctl install "$DEVICE" "$APP"

echo "Setting onboarding complete and seeding demo data..."
xcrun simctl spawn "$DEVICE" defaults write "$BUNDLE_ID" VGB.hasCompletedOnboarding -bool true 2>/dev/null || true
xcrun simctl terminate "$DEVICE" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$DEVICE" "$BUNDLE_ID" -SeedDemoData
sleep 4

mkdir -p "$SCREENSHOTS_DIR"

capture() {
  local tab=$1
  local file=$2
  xcrun simctl terminate "$DEVICE" "$BUNDLE_ID" 2>/dev/null || true
  sleep 1
  xcrun simctl launch "$DEVICE" "$BUNDLE_ID" -ScreenshotTab "$tab"
  sleep 6
  xcrun simctl io "$DEVICE" screenshot "$SCREENSHOTS_DIR/$file"
  echo "Saved $file"
}

echo "Capturing Game Catalog..."
capture 0 "01-game-catalog.png"
echo "Capturing Rankings..."
capture 1 "02-rankings.png"
echo "Capturing Stats..."
capture 2 "03-stats.png"

echo "Done. Screenshots in $SCREENSHOTS_DIR"