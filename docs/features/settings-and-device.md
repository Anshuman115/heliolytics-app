# Feature — Onboarding, device setup, Settings, cloud API & logging

First-launch onboarding, the strap-pairing wizard, and the "More" tab: cloud
config, band alerts, diagnostics, app logs, about.

## Onboarding gate

A new `onboardingComplete` flag (secure storage, same seam as the auth key)
gates the whole app on first launch. `OnboardingNotifier`
(`providers/onboarding_provider.dart`) starts optimistic
(`onboardingComplete: true`) and corrects itself async — same rationale as
`SessionSnapshot.initial` defaulting to `idle`: avoids flashing the intro
screen on every cold start before secure storage resolves.

`GoRouter`'s redirect (`router/app_router.dart`) checks onboarding *before*
the auth-key check: `!onboardingComplete → /intro`, then the existing
`noAuthKey → /auth` gate, in that order. A user who hasn't finished
onboarding never reaches any app route except `/intro` and `/profile`.

Flow: `IntroScreen` → `ProfileScreen` (name/age/height/weight, submitted to
an assumed `POST /api/v1/profile` — the app never blocks on this call
succeeding, since the profile is saved locally regardless) → the existing
`AuthKeyScreen`.

**Existing installs are not migrated** — every user, new or existing, goes
through onboarding once after this shipped. Deliberate: the app never
collected a profile before, so a one-time capture is reasonable and no
prior data is lost (auth key/MAC are untouched).

## Device setup wizard

Reached from Settings → "Sync" / "Connect strap", not from the app-wide
router redirect (unlike onboarding, this is opt-in navigation). Five steps,
each its own screen, chained via `context.push`:

```
/setup/bluetooth  → SetupBluetoothScreen    Bluetooth on?
/setup/permission → SetupPermissionScreen   nearby-devices permission
/setup/scan       → DeviceScanScreen        pick the strap, saves MAC
/setup/connect    → SetupConnectScreen      connect + authenticate
/setup/backfill-days → SetupBackfillDaysScreen   first-sync days picker
```

`DeviceScanScreen` shows every nearby BLE device, badges Amazfit-Helio-name
matches, but **no longer auto-connects** — the user must tap explicitly
(older versions silently picked the best match; that surprised people who
had multiple straps nearby). Picking a device saves its MAC via
`syncOrchestratorProvider.notifier.saveMac()` and pushes to the connect
step, which calls `.connectForSetup()` to connect and authenticate without
starting a sync. The backfill-days step then stores the selected range,
navigates to Home, and starts the first sync explicitly.

The backfill-days picker (chips: 7/14/30/60 + custom, no default) writes to
`backfillDaysProvider` (`StateProvider<int?>`) — consumed once by the
*first* sync only (see [ble-sync.md](ble-sync.md)), then reset to `null`
only if that sync actually succeeds, so a failed first attempt doesn't
silently lose the user's chosen backfill window.

## Strap auth key

The strap's BLE auth key is **32 hex characters**. `AuthKeyValidator`
(`services/ble/auth/auth_key_validator.dart`) normalizes (trim + lowercase) and
enforces `^[0-9a-f]{32}$` before anything touches BLE.

Stored via `AuthKeyStorage` → `AuthKeyStore` → `SecureKeyStore`
(`services/ble/auth/secure_key_store.dart`) → `flutter_secure_storage`. Never
in plain prefs, never logged. `AuthKeyStore` is the seam — `SecureKeyStore`
is the real implementation; anything needing to fake it for testing only
needs to implement the same 3-method interface.

## Cloud API config

`ApiSettingsScreen` (Settings → Cloud API) + `ApiConfigStorage`
(`services/config/api_config_storage.dart`) store two values in secure storage:

| Key | Meaning |
|---|---|
| `api_base_url` | Go server base URL |
| `signing_secret` | HMAC secret for request auth |

There's a legacy migration: an older `api_key` entry is read once, rewritten to
`signing_secret`, and deleted. Leave that path alone until installs predating it are
gone.

`apiConfiguredProvider` gates sync — `SyncWindow.plan` refuses to fetch when the API
isn't configured, because a sync with nowhere to upload just burns battery.

`ApiConfigFormNotifier` compares trimmed values before replacing the
configuration. On an actual URL or signing-secret change,
`HealthDataRefreshCoordinator` clears day-bundle and daily-health-score disk
caches before saving the new values. It then invalidates all server-derived
providers, including activity history, details, trends, and sync status. This
prevents data from one server or credential set appearing under another.

## Request auth

Every API call carries `X-Heliolytics-Token`, minted by
`services/network/heliolytics_token.dart`:

```
ts   = unix seconds (UTC)
nonce = 16 random bytes, hex
sig  = HMAC-SHA256(secret, "ts:nonce")
token = "ts.nonce.sig"
```

**This must stay byte-identical to Go `auth.SignToken` and the web's
`mintHeliolyticsToken`.** Three implementations, one format — change one and you
break the other two. The server rejects replayed nonces and stale timestamps.

`MetricsApiTransport` requests a dynamic response body so a plain-text error
cannot fail as a String-to-Map cast before its status is inspected. HTTP
statuses and malformed successful responses map to typed errors. A `401`
causes exactly one immediate retry, and the retry mints a new token instead of
reusing the rejected nonce. There is no wall-clock sleep between attempts.
Only bundle list endpoints declared optional by `MetricsApiClient` may turn a
`404` into an empty list; authentication, timeout, and malformed-payload errors
always propagate.

`api_dio.dart` builds the Dio client; `AppLogger.createApiDio()` attaches
Talker's Dio logger.

## Settings structure

`SettingsHubScreen` (`screens/settings_hub_screen.dart`) starts with an unframed,
image-led device status area: connection state, last sync, strap visual, battery,
and sync/upload/scan commands. Below it, `SettingsMenuList`
(`widgets/settings/settings_menu_list.dart`) groups the six destinations into
Connections and App & Support surfaces. It owns the row list and its provider
watches, keeping the hub screen a thin composition:

| Row | Route | Screen |
|---|---|---|
| Cloud API | `/settings/api` | `ApiSettingsScreen` |
| Amazfit Auth Key | `/settings/auth-key` | `AuthKeyScreen` |
| Band Alerts | `/settings/band-alerts` | `BandAlertsSettingsScreen` |
| Diagnostics | `/settings/diagnostics` | `DiagnosticsScreen` |
| App Logs | `/settings/logs` | `AppLogsScreen` |
| About | `/settings/about` | `AboutScreen` |

Band Alerts detail (toggle, readiness checklist, call-pattern/apps rows) —
see [band-alerts.md](band-alerts.md). Diagnostics groups
`TestVibrationCard`, `TestVibrationPatternCard`, `RawDumpCard` — vibration
test, saved-pattern test, raw strap-session dump/share.

## App logs (persistent, app-wide)

`AppLogger` (`utils/app_logger.dart`) wraps a `Talker` instance, active in
**every** build including release (earlier versions only logged in debug —
a production user's bug report is now actually debuggable). Every
`AppLogger.instance.log(...)` call, every Dio request/response, and every
uncaught Flutter/platform error flows through the same `Talker`.

Persistence: `LogFileStore` (`utils/log_file_store.dart`) writes each log
event as one JSON line to a rotating set of files
(`logs/app-0.jsonl` … `app-4.jsonl` in app documents, 1 MB cap each, 5 files
max — ~5 MB total). On startup, `AppLogger` replays all persisted lines
into `Talker`'s in-memory history *before* live logging resumes, so the
viewer shows history across restarts, not just the current session. A
`_replaying` guard stops the replay itself from being re-persisted (without
it, every launch would rewrite its whole history back to disk).

All file I/O in `LogFileStore` is best-effort — `append`/`readAllLines`
never throw. Logging must never crash the app or block a caller.

The viewer at `/settings/logs` (`AppLogsScreen`) wraps `talker_flutter`'s
ready-made `TalkerScreen` unstyled — deliberately not restyled to match
`HelioTheme`, since this is a diagnostics screen, not a product surface.

**HTTP response bodies are persisted in plaintext** (server-parsed health
metrics, potentially). Request/response headers are redacted
(`_hiddenHeaders`: token, auth, cookie) but body content is not. This is a
deliberate choice — app-private storage on Android isn't exposed to other
apps, and full response bodies are valuable for debugging real user
issues. If that tradeoff ever needs revisiting, `createApiDio()`'s
`TalkerDioLoggerSettings(printResponseData: ...)` is the one flag to flip.

## Diagnostics

- `StrapDumpProvider` / `strap_dump_service.dart` — raw session capture for offline
  replay; feeds a local validation workflow that scores parser output against
  ground-truth exports
- `AppLogger.instance.log(...)` — the only sanctioned logging call. No `print()`.

## Key files

| File | Role |
|---|---|
| `providers/onboarding_provider.dart` | Onboarding gate state |
| `screens/intro_screen.dart` / `profile_screen.dart` | First-launch flow |
| `screens/setup_bluetooth_screen.dart` … `setup_backfill_days_screen.dart` | Device setup wizard, 5 steps |
| `providers/backfill_days_provider.dart` | Wizard → first-sync handoff |
| `screens/settings_hub_screen.dart` | Settings root |
| `widgets/settings/device_hero_card.dart` | Device status, product visual, and commands |
| `widgets/settings/settings_menu_list.dart` | The 6 navigable rows in two groups |
| `screens/api_settings_screen.dart` | Server config form |
| `screens/band_alerts_settings_screen.dart` | Band alerts detail |
| `screens/diagnostics_screen.dart` | Vibration test, raw dump |
| `screens/app_logs_screen.dart` | Log viewer |
| `screens/about_screen.dart` | Build info, version |
| `screens/auth_key_screen.dart` | Key entry |
| `screens/device_scan_screen.dart` | BLE scan (wizard step 3) |
| `services/ble/auth/auth_key_validator.dart` | Key format rules |
| `services/ble/auth/secure_key_store.dart` | `AuthKeyStore` implementation |
| `services/config/api_config_storage.dart` | Secure config |
| `services/network/heliolytics_token.dart` | Request signing |
| `services/network/metrics_api_transport.dart` | Response decoding, status mapping, bounded auth retry |
| `providers/health_data_refresh_coordinator.dart` | Cache-safe refresh and config invalidation |
| `services/ble/pairing_curve_b163.dart` | Pairing crypto |
| `utils/app_logger.dart` | Process-wide logging + persistence |
| `utils/log_file_store.dart` | Rotating JSON-lines log files |
