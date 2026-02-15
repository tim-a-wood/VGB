#!/bin/bash
# Capture screenshot from booted iOS Simulator for App Store.
# Usage: ./capture-screenshot.sh [number]
# Example: ./capture-screenshot.sh 1  → screenshots/01.png

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCREENSHOTS_DIR="$REPO_ROOT/screenshots"
NUMBER="${1:-1}"

mkdir -p "$SCREENSHOTS_DIR"
OUTPUT="$SCREENSHOTS_DIR/$(printf "%02d" "$NUMBER").png"

echo "Capturing screenshot from Simulator..."
xcrun simctl io booted screenshot "$OUTPUT"
echo "Saved: $OUTPUT"
