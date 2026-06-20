#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE="${1:-build.env}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE — copy build.env.example and fill secrets."
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${API_URL:?API_URL missing in $ENV_FILE}"
: "${API_SIGNING_SECRET:?API_SIGNING_SECRET missing in $ENV_FILE}"

flutter pub get
flutter build apk --profile \
  --no-tree-shake-icons \
  --dart-define="API_URL=${API_URL}" \
  --dart-define="API_SIGNING_SECRET=${API_SIGNING_SECRET}"

echo ""
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
echo "Install: adb install -r build/app/outputs/flutter-apk/app-release.apk"
