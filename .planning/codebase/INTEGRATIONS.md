# External Integrations

**Analysis Date:** 2026-08-23

## APIs & External Services

**Heliolytics Go API:**
- Configurable HTTPS base URL - receives raw strap sessions and serves server-parsed health metrics
  - SDK/Client: `dio` through `lib/services/network/metrics_api_transport.dart`, `lib/services/metrics_api_client.dart`, `lib/services/cloud_sync_repository_impl.dart`, and `lib/services/network/profile_api_client.dart`
  - Auth: `X-Heliolytics-Token`, a short-lived HMAC-SHA256 token minted from the configured signing secret in `lib/services/network/heliolytics_token.dart`
  - Endpoints: `/api/v1/ingest`, `/api/v1/coverage`, `/api/v1/daily-metrics`, `/api/v1/daily-health-scores`, `/api/v1/sleep`, `/api/v1/metrics/series`, `/api/v1/metrics/hr`, `/api/v1/metrics/temperature`, `/api/v1/metrics/workouts`, `/api/v1/metrics/activity-sessions`, and `/api/v1/profile`

**Android platform services:**
- Android Bluetooth and notification APIs - BLE permissions, notification listener events, foreground connected-device service, vibration, and phone/Bluetooth adapter state through `android/app/src/main/kotlin/`
- Flutter method/event channels `com.heliolytics/band_alerts` - bridge band alerts behavior between Dart and Android in `lib/constants/constants.dart` and Android services

## Data Storage

**Databases:**
- None in the mobile app. PostgreSQL/TimescaleDB belongs to the external Go API, as documented in `README.md`.

**File Storage:**
- App-private filesystem only - JSONL logs and transient diagnostic files through `path_provider` and `lib/utils/app_logger.dart`

**Caching:**
- Hive box `cached_days_box` - per-day server-derived `DayBundle` JSON in `lib/services/cache/daily_bundle_cache_storage.dart`
- `shared_preferences` - small daily health score cache in `lib/services/cache/daily_health_scores_cache_storage.dart`
- Secure storage is used for credentials and configuration, not as a remote cache

## Authentication & Identity

**Auth Provider:**
- Custom shared-secret request authentication - no third-party login provider
  - API URL and signing secret are stored by `lib/services/config/api_config_storage.dart` via `flutter_secure_storage`
  - Strap auth key is stored separately by `lib/services/ble/auth/secure_key_store.dart` and is used only in the BLE handshake
  - API token format is `ts.nonce.sig`, with HMAC-SHA256 over `ts:nonce`

## Monitoring & Observability

**Error Tracking:**
- None detected. No Firebase Crashlytics, Sentry, or hosted error SDK is configured.

**Logs:**
- Talker-based structured logs via `lib/utils/app_logger.dart`, including Dio logging and app-private JSONL files under the logs directory

## CI/CD & Deployment

**Hosting:**
- Android Play Store release; API hosting is external and configured by URL

**CI Pipeline:**
- GitHub metadata exists under `.github/`; no complete hosted deployment workflow was detected during this audit

## Environment Configuration

**Required env vars:**
- Build-time names: `API_URL`, `API_SIGNING_SECRET`, `STRAP_AUTH_KEY`, and `STRAP_MAC` in `lib/constants/constants.dart`
- Interactive setup stores API URL and signing secret in secure storage; store builds can therefore omit baked-in values

**Secrets location:**
- Local build inputs are supplied through ignored `build.env`; runtime credentials are entered in-app and stored through `flutter_secure_storage`
- Android release signing optionally reads `android/key.properties`; its contents are not inspected

## Webhooks & Callbacks

**Incoming:**
- None detected. Android notification callbacks are local platform events, not network webhooks.

**Outgoing:**
- Multipart raw-session upload to the Go API `/api/v1/ingest`; metrics and profile calls are ordinary HTTPS requests

---

*Integration audit: 2026-08-23*
