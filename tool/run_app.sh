#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE="${1:-build.env}"
DEVICE_ID="${2:-}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Copy build.env.example and fill secrets."
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${API_URL:?API_URL missing in $ENV_FILE}"
: "${API_SIGNING_SECRET:?API_SIGNING_SECRET missing in $ENV_FILE}"

args=(
  flutter run
  --no-pub
  --dart-define="API_URL=${API_URL}"
  --dart-define="API_SIGNING_SECRET=${API_SIGNING_SECRET}"
)

if [[ -n "$DEVICE_ID" ]]; then
  args+=(--device-id "$DEVICE_ID")
fi

exec "${args[@]}"
