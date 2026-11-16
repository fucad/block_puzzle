#!/usr/bin/env bash
# Captures raw store screenshots from the iOS simulator using the in-app
# screenshot mode (lib/dev/screenshot_mode.dart). Output: docs/store/raw/.
# Usage: tool/capture_screenshots.sh ["iPhone 17 Pro Max"]
set -euo pipefail
cd "$(dirname "$0")/.."
DEVICE="${1:-iPhone 17 Pro Max}"
BUNDLE=games.adfree.blockPuzzle
OUT=docs/store/raw
mkdir -p "$OUT"
UDID=$(xcrun simctl list devices available | grep -F "$DEVICE (" | head -1 | grep -oE '[0-9A-F-]{36}')
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged \
  --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi
for scene in ${SCENES:-menu classic map gems stats}; do
  flutter build ios --simulator --debug --dart-define=SHOT="$scene" >/dev/null
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl install "$UDID" build/ios/iphonesimulator/Runner.app
  xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null
  sleep "${SHOT_WAIT:-12}"   # debug JIT start + entry animations
  xcrun simctl io "$UDID" screenshot "$OUT/$scene.png" >/dev/null
  echo "captured $OUT/$scene.png"
done
xcrun simctl status_bar "$UDID" clear
