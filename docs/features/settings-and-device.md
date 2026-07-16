# Feature — Settings, device & cloud API

The "More" tab: pair a strap, point the app at a server, test vibration, read
diagnostics.

## Strap auth key

The strap's BLE auth key is **32 hex characters**. `AuthKeyValidator`
(`services/ble/auth/auth_key_validator.dart`) normalizes (trim + lowercase) and
enforces `^[0-9a-f]{32}$` before anything touches BLE.

Stored via `AuthKeyStorage` → `AuthKeyStore` → `flutter_secure_storage`. Never in
plain prefs, never logged.

Presence of a key is the app's auth gate: `GoRouter` redirects to `/auth` only when
no key is stored. `SessionState.noAuthKey` is the initial state otherwise.

## Device scan & pairing

`DeviceScanScreen` finds straps over BLE. Pairing crypto lives in
`services/ble/pairing_curve_b163.dart` (Huami curve-B163 handshake), driven by
`device_handshake.dart`. Framing is `gatt_framing.dart`; encrypted writes go through
`encrypted_endpoint.dart`.

`find_device_service.dart` is the "make it buzz so I know which one" path —
endpoint `0x001a`, `0x03` start / `0x06` stop. Also surfaced as Settings → Test
vibration (see [band-alerts.md](band-alerts.md) on session warmth).

## Cloud API config

`ApiSettingsScreen` + `ApiConfigStorage` (`services/config/api_config_storage.dart`)
store two values in secure storage:

| Key | Meaning |
|---|---|
| `api_base_url` | Go server base URL |
| `signing_secret` | HMAC secret for request auth |

There's a legacy migration: an older `api_key` entry is read once, rewritten to
`signing_secret`, and deleted. Leave that path alone until installs predating it are
gone.

`apiConfiguredProvider` gates sync — `SyncWindow.plan` refuses to fetch when the API
isn't configured, because a sync with nowhere to upload just burns battery.

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

`api_dio.dart` builds the Dio client and attaches Talker logging in debug.

## Diagnostics

- `SyncLogPanel` — live sync log from `SyncSessionLog`
- `StrapDumpProvider` / `strap_dump_service.dart` — raw session capture for offline
  replay; feeds a local validation workflow that scores parser output against
  ground-truth exports
- `AppLogger.instance.log(...)` — the only sanctioned logging call. No `print()`.

## Key files

| File | Role |
|---|---|
| `screens/settings_hub_screen.dart` | Tab root |
| `screens/api_settings_screen.dart` | Server config form |
| `screens/auth_key_screen.dart` | Key entry |
| `screens/device_scan_screen.dart` | BLE scan |
| `services/ble/auth/auth_key_validator.dart` | Key format rules |
| `services/config/api_config_storage.dart` | Secure config |
| `services/network/heliolytics_token.dart` | Request signing |
| `services/ble/pairing_curve_b163.dart` | Pairing crypto |
