# Settings, setup and local data

Source review: 7 September 2026.

## Onboarding and profile

The router checks onboarding before the strap-auth state. Incomplete onboarding
allows Intro/Profile; the missing-key state then routes to `/auth`.
The profile contains name, age, height and weight and is saved in secure storage.
`ProfileApiClient.submitProfile` makes a best-effort `PUT /api/v1/profile` when
configured. A failure is logged and does not undo the local save.

The API body uses `height_cm` and `weight_kg`. Local profile JSON uses `heightCm`
and `weightKg`. There is no server profile read in the current app.

## Device setup

The five setup routes are:

1. `/setup/bluetooth`: Bluetooth prompt.
2. `/setup/permission`: permission step.
3. `/setup/scan`: select a device and save its address.
4. `/setup/connect`: authenticate without beginning historical sync.
5. `/setup/backfill-days`: select first-sync history, then start sync.

The selected backfill value is used when coverage says the backend is empty.
It is retained after a failed first attempt and cleared after a successful sync.
It is not an override for every later fetch.

The band auth key is 32 hex characters. Validation normalizes it before secure
storage. It is separate from the API signing secret.

## Cloud configuration

`ApiConfigStorage` stores the base URL and signing secret in secure storage.
It migrates a legacy `api_key` entry to `signing_secret` when needed.
`main.dart` may seed defaults in debug or a build supplied with both API defines;
do not describe default seeding as debug-only.

Configuration replacement compares trimmed values. On a real change,
`HealthDataRefreshCoordinator` clears the two disk health caches before saving,
then invalidates the main health providers. Its actual identifier list is the
source of truth for which provider families are refreshed.

Signed data requests carry `X-Heliolytics-Token` in `ts.nonce.sig` format. HMAC-SHA256
signs `ts:nonce`. The format must match Go and Web byte-for-byte.
`/health` is public and used for connectivity checks.

`MetricsApiTransport` maps HTTP and decode failures to typed errors. A 401 gets
one immediate retry with a new token. Only explicitly optional bundle endpoints
may treat a 404 as an empty list; other errors propagate.

## More tab destinations

| Destination | Route |
|---|---|
| Cloud API | `/settings/api` |
| Strap auth key | `/settings/auth-key` |
| Band alerts | `/settings/band-alerts` |
| Diagnostics | `/settings/diagnostics` |
| App logs | `/settings/logs` |
| About | `/settings/about` |

Device controls show connection, battery and sync status. Band-alert settings
also have app selection and call/app vibration-pattern pages. See
[band alerts](band-alerts.md) for the shared connection constraints.

## Persistence and logs

`AppLogger` uses Talker and a rotating `LogFileStore`. Logs survive restarts,
including release builds. Replay avoids writing the same loaded logs again.
The store keeps up to five files at approximately 1 MB each, best-effort.

The configured API logger uses `printResponseData: !kReleaseMode`. Release API
response bodies are excluded from its formatted log messages; debug may include
them. Selected headers are redacted. This does not sanitize every custom message
or request body. There is no automatic log upload.

Closed-day health responses are cached separately in Hive/SharedPreferences.
Normal sync also stores session/catalog metadata. Diagnostics can capture and
share raw band files on explicit user action.

There is no separate biometric/PIN app lock in the current source. See
[data handling](../local/PRIVACY.md) for storage and removal behavior.

## Source map

- `lib/providers/onboarding_provider.dart`: onboarding/profile state.
- `lib/services/network/profile_api_client.dart`: actual profile PUT contract.
- `lib/services/config/api_config_storage.dart`: credentials/default migration.
- `lib/services/network/metrics_api_transport.dart`: signed metric transport.
- `lib/widgets/settings/settings_menu_list.dart`: destination list.
- `lib/utils/app_logger.dart`, `lib/utils/log_file_store.dart`: logging.
