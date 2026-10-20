# Settings, setup and local data

## Onboarding and profile

The router checks onboarding before the strap-auth state. Incomplete onboarding
allows Intro/Profile; the missing-key state then routes to `/auth`.

The profile has five optional fields: name, birth date, sex, height and weight.
Every field may be unset. Birth date is a date-only value validated against
calendar rollover, `>1900-01-01` and `<= today IST`. Sex is `male`, `female` or
unset and is never inferred. A one-time storage reset clears any pre-v4 local
profile and asks again, so no approximate date of birth is derived from an old age.

`ProfileApiClient.submitProfile` sends one pre-encoded signed PUT with every
required camelCase key, nulls included, and requires a 204. A local save and a
cloud save are reported separately: if the network call fails the screen says the
profile is saved on this device only, keeps the values and offers a retry. A 204
triggers a health and cache refresh because profile edits recompute load and
readiness. There is no server profile read route.

Missing birth date or sex leaves the Banister training-load estimate unavailable
rather than estimated.

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
storage. It is separate from the phone API key.

## Cloud configuration

`ApiConfigStorage` stores the API origin and a `phone.<64 lowercase hex>` API key in
secure storage under `api_base_url` and `api_key_v2`. Settings rejects web keys,
unknown kids, uppercase or short secrets and malformed values before any request.

There is no automatic migration from the v1 settings. The old `signing_secret` and
`api_key` slots are cleared once at startup without logging their values, and the
screen then asks for the new phone API key. `--dart-define=API_URL` may seed an
origin at build time; the API key is never a build input.

The origin is an HTTPS origin with an optional trailing slash and no path, query,
fragment or userinfo. Plain HTTP is allowed only for a loopback development host
outside release builds, and a release build never enables that exception through a
dart-define. Redirects are not followed for signed requests.

Configuration replacement compares trimmed values. On a real change,
`HealthDataRefreshCoordinator` clears the disk caches before saving, then
invalidates the main health providers. Its actual identifier list is the source of
truth for which provider families are refreshed.

### Signing

Every authenticated request carries:

- `X-Heliolytics-Auth: v2.<kid>.<ts>.<nonce>.<sig>`
- `X-Heliolytics-Content-SHA256: <hex>`

The HMAC-SHA256 key is the raw 32 secret bytes. The signed text is `v2`, kid,
decimal timestamp, nonce, uppercase method, escaped path, raw query, lowercase body
hash and the exact final Content-Type, joined with `\n` and no extra trailing
newline. Multipart bodies are finalized once and signed after the boundary is
frozen. A GET has an empty body and an empty Content-Type.

`MetricsApiTransport` maps HTTP and decode failures to typed errors. A 401 reports
key and clock guidance and is never retried automatically, nor is any other
deterministic 4xx. A 429 or 503 surfaces its `Retry-After`. There are no optional
bundle endpoints: a 404 on a read route propagates. `/health` is public and used for
connectivity checks.

## More tab destinations

| Destination | Route |
|---|---|
| Cloud API | `/settings/api` |
| Strap auth key | `/settings/auth-key` |
| Band alerts | `/settings/band-alerts` |
| Diagnostics | `/settings/diagnostics` |
| App logs | `/settings/logs` |
| About | `/settings/about` |

Device controls show connection, battery and sync status. `lastSyncedAt` is the
confirmed backend `lastIngestAt` only. Coverage failure shows an error with retry,
and a reminder appears only after more than 72 hours without a confirmed sync.
Band-alert settings also have app selection and call/app vibration-pattern pages.
See [band alerts](band-alerts.md) for the shared connection constraints.

## Data caveats

Measured SpO2 comes only from type `0x25`. Type `0x26` contains sleep-breathing
placeholders and is uploaded as `raw_only`; it is never shown as oxygen data.
Physical SpO2 verification on hardware is still pending.

## Persistence and logs

`AppLogger` uses Talker and a rotating `LogFileStore`. Logs survive restarts,
including release builds. Replay avoids writing the same loaded logs again.
The store keeps up to five files at approximately 1 MB each, best-effort.

The configured API logger uses `printResponseData: !kReleaseMode`. Release API
response bodies are excluded from its formatted log messages; debug may include
them. `X-Heliolytics-Auth`, `X-Heliolytics-Content-SHA256` and API-key fields are
redacted. Persisted logs never contain the key, auth headers, health bodies,
multipart files or profile input. There is no automatic log upload.

Closed-day health responses are cached in Hive. Normal sync also stores
session/catalog metadata. Diagnostics can capture and share raw band files on
explicit user action.

There is no separate biometric/PIN app lock in the current source.

## Source map

- `lib/providers/onboarding_provider.dart`: onboarding/profile state.
- `lib/services/network/profile_api_client.dart`: actual profile PUT contract.
- `lib/services/config/api_config_storage.dart`: origin and API-key storage.
- `lib/services/network/request_signer.dart`: v2 key grammar and signing.
- `lib/services/network/metrics_api_transport.dart`: signed request transport.
- `lib/widgets/settings/settings_menu_list.dart`: destination list.
- `lib/utils/app_logger.dart`, `lib/utils/log_file_store.dart`: logging.

Validation: not run for this revision.
