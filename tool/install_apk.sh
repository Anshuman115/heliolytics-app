#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

APK="build/app/outputs/flutter-apk/app-profile.apk"
PKG="com.heliolytics.heliolytics"

if [[ ! -f "$APK" ]]; then
  echo "Missing $APK -- run ./tool/build_apk.sh first."
  exit 1
fi

if ! adb devices | grep -q 'device$'; then
  echo "No adb device connected."
  adb devices -l
  exit 1
fi

echo "Uninstalling old $PKG (ignores error if not installed)..."
adb uninstall "$PKG" >/dev/null 2>&1 || true

echo "Installing $APK..."
adb install "$APK"

echo "Done. Open More tab -> About and confirm Build v3-ui2."