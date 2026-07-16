# Heliolytics

**A self-hosted health platform for a BLE fitness band** — built end-to-end from the
device's wireless protocol up to the mobile UI. It reverse-engineers the band's
Bluetooth Low Energy protocol, uploads raw sessions to a Go ingestion/analytics
backend, and renders sleep, recovery, and activity insights in a Flutter app.

> **This repository is the Flutter mobile client.** It pairs with a Go API + PostgreSQL/TimescaleDB
> backend and a Next.js dashboard — see [System architecture](#system-architecture).

---

## Engineering highlights

- **Reverse-engineered the wearable's BLE protocol from scratch** (no vendor SDK):
  ECDH key exchange on the binary curve `sect163k1`, an AES-128 challenge-response
  handshake, and a custom chunked transport over GATT — all implemented in Dart.
- **Binary health-data decoding** — per-type-code parsers for ~20 data streams
  (per-minute activity & heart rate, sleep stages, HRV, SpO₂, skin temperature,
  workouts, respiratory rate…) across two distinct on-device timestamp models.
- **Validated against the vendor's own data export** — sleep-stage minutes matched on
  26/27 nights; per-minute heart rate and full-day step totals matched **exactly** in
  side-by-side validation.
- **Thin-client, server-authoritative sync** — the phone uploads raw session bytes; the
  Go server owns all parsing, storage, and per-type "coverage" windows. Fetch state lives
  on the server, so it survives app reinstalls, and **no health data is persisted on the device**.
- **Science-backed recovery score** — a daily readiness score derived from HRV
  (`ln(RMSSD)`), resting heart rate, sleep, and respiratory rate compared to a personal
  rolling baseline, following established HRV-guided-training research (Plews et al.),
  with documented weighting and cold-start handling.
- **Production-minded engineering** — TimescaleDB hypertables for per-minute time series;
  idempotent ingest (overlapping re-syncs never double-count steps); lazy-loaded metrics
  API to cut mobile bandwidth; a layer-first architecture with a one-responsibility,
  ≤150-lines-per-file discipline; unit-tested parsers and scoring.

---

## System architecture

Three repositories, one platform:

| Repo | Role | Stack |
|------|------|-------|
| **Heliolytics_App** (this repo) | BLE sync, raw upload, health UI | Flutter · Dart · Riverpod |
| **Heliolytics** | Ingest, parse, store, metrics API | Go · PostgreSQL + TimescaleDB · Docker |
| **Heliolytics_Web** | Web dashboard | Next.js |

```
 Band ──BLE (ECDH+AES, chunked)──►  Flutter app  ──HTTPS (HMAC)──►  Go API
                                    (raw bytes)        POST /ingest     │
                                                                        ▼
                                                            parse → PostgreSQL/TimescaleDB
                                                                   ╱              ╲
                                                       Flutter GET /metrics     Next.js dashboard
```

All health parsing happens **server-side** after ingest; the app keeps only the minimal
on-device logic needed to page data off the band over BLE.

---

## How it works

1. **Pair** — the user provides the band's auth key once (stored in Android
   EncryptedSharedPreferences / iOS Keychain). No third-party cloud login.
2. **Sync** — the app performs the ECDH + AES handshake, then fetches each data type in
   chunks over GATT. The fetch window per data type comes from the server's coverage
   API, so the client stays stateless and reinstall-safe.
3. **Upload** — raw session bytes are uploaded with a short-lived HMAC-signed token.
4. **Parse & store** — the Go server decodes each binary stream into typed samples and
   writes them to TimescaleDB; daily rollups (steps, sleep, recovery, …) are computed on ingest.
5. **Render** — the app reads daily metrics and per-minute series from the metrics API and
   draws rings, charts, and a health-monitor grid.

---

## Tech stack

**Mobile:** Flutter, Dart, Riverpod, `flutter_blue_plus`, `flutter_secure_storage`,
GoRouter, `fl_chart`, Dio · **Crypto:** ECDH (`sect163k1`), AES-128, HMAC ·
**Backend (sibling repo):** Go, PostgreSQL + TimescaleDB, `sqlc`, Docker · **Web:** Next.js

---

## Project structure (this repo)

Layer-first, one responsibility per file:

```
lib/
  screens/          Full pages (Home, Sleep, Activity, Settings, metric detail…)
  widgets/          Screen-specific UI chunks (charts, sections, settings cards)
  providers/        Riverpod state + orchestration
  services/
    ble/            BLE protocol, auth handshake, sync pipeline, per-type parsers
    network/        Dio client + HMAC token minting
    config/         Secure-storage config
  models/           Domain + JSON entities
  router/           GoRouter + auth redirect
  utils/            Logging, formatters, time/zone helpers
  constants/        App-wide literals
  design_system/    Tokens, theme, reusable components
```

**Flow:** `screens → providers → services → models` · See [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Build & run

```bash
flutter pub get
flutter run -d android        # USB debugging enabled; auto-picks a single device
```

**Personal APK** (API URL + signing secret baked in at build time):

```bash
cp build.env.example build.env   # set API_URL and API_SIGNING_SECRET
./tool/build_apk.sh
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

**Play Store AAB** (API configured in-app on first launch):

```bash
flutter build appbundle --release
```

Start the backend stack from the **Heliolytics** repo first. The app mints short-lived
HMAC tokens itself — no tokens are pasted by hand.

---

## Security & privacy

- The band **auth key** is used only over BLE — it is never sent to the API.
- API requests are signed with short-lived **HMAC** tokens; credentials live in encrypted
  device storage.
- Device lock (PIN/biometrics) gates access when a screen lock is set.
- Health data is uploaded only to the server **you** configure; nothing is persisted on the
  device. See [PRIVACY.md](PRIVACY.md).

---

## Documentation

Engineering rules and layer boundaries live in [CLAUDE.md](CLAUDE.md). One guide per
feature, written to be read before changing that area:

| Guide | Covers |
|-------|--------|
| [BLE sync](docs/features/ble-sync.md) | Coverage-driven fetch windows, per-type paging, raw upload |
| [Band alerts](docs/features/band-alerts.md) | Call/app forwarding, vibration patterns, session locking |
| [Home & rings](docs/features/home-and-rings.md) | Shell, tabs, and the two-tier metrics split |
| [Sleep](docs/features/sleep.md) | Hypnogram, stage bars, clock-axis consistency chart |
| [Activity](docs/features/activity.md) | Workouts, auto-detected sessions, HR zones |
| [Settings & device](docs/features/settings-and-device.md) | Auth key, pairing, cloud API, request signing |

---

## Status

Actively developed; deployed to the Play Store from this repo. Current line of work
(`v6`): band alerts — forwarding incoming calls and allow-listed app notifications to
the strap with user-editable vibration patterns — plus per-workout heart-rate zones
and a rebuilt sleep view.

Earlier lines brought the server-computed recovery score, lazy-loaded metrics for
lower bandwidth, and idempotent step ingestion.

---

## Development notes

This project is built intensively with [Claude Code](https://claude.com/claude-code)
as an engineering assistant — architecture, protocol decoding, and validation are
reviewed and directed by hand, and the AI-assisted commits are attributed as such in
the history. The rules the assistant works under are the same ones in
[CLAUDE.md](CLAUDE.md).

---

## License

[Apache License 2.0](LICENSE).
