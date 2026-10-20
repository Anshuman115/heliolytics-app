#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE="${1:-build.env}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Copy build.env.example and set the API origin."
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${API_URL:?API_URL missing in $ENV_FILE}"

# Flutter 3.32.x may exit non-zero from pub get if no device is connected.
# Dependencies still resolve fine — ignore the exit code.
flutter pub get || true
flutter build apk --debug \
  --no-tree-shake-icons \
  --dart-define="API_URL=${API_URL}"

echo ""
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
echo "Install: adb install -r build/app/outputs/flutter-apk/app-release.apk"
