# Heliolytics App

Flutter mobile client for Heliolytics: BLE strap sync, cloud upload, health UI.

Part of a **3-repo system**:

| Repo | Role |
|------|------|
| **Heliolytics_App** (here) | Flutter · BLE · Play Store |
| **Heliolytics** | Go API · PostgreSQL |
| **Heliolytics_Web** | Next.js dashboard |

## Run (debug)

```bash
flutter pub get
flutter run -d android
```

Connect your phone over USB with **USB debugging** enabled. If only one Android device is attached, `flutter run -d android` picks it automatically.

## Release build

1. Copy `android/key.properties.example` → `android/key.properties` and fill in your release keystore
2. Build AAB for Play Store:

```bash
flutter build appbundle --release
```

Personal APK (API URL + key baked in at build time):

```bash
cp build.env.example build.env
# edit build.env — same URL/secret as Heliolytics/deploy/.env
chmod +x tool/build_apk.sh
./tool/build_apk.sh
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Play Store AAB (configure API in app Settings after install):

```bash
flutter build appbundle --release
```

## API setup

1. Start the stack from the **Heliolytics** repo (`deploy/install.sh`)
2. Personal install: set `API_URL` and `API_SIGNING_SECRET` in `build.env` before `./tool/build_apk.sh`
3. Play Store / manual: **Settings → Cloud API** on first launch

The app mints short-lived HMAC tokens — you never paste tokens manually.

## Security

- Strap **auth key** (first-time setup) is BLE-only — not sent to the API
- **API key** signs requests to your Heliolytics server
- Device lock (PIN/biometrics) required when screen lock is enabled on the phone

## Privacy

See [PRIVACY.md](PRIVACY.md) for Play Store / data handling summary.

## Layout

Layer-first project structure (separation of concerns):

```
lib/
  screens/          UI pages (Home, Sleep, Settings, …)
  widgets/          Screen-specific UI chunks (charts, sections)
  providers/        Riverpod state (controllers)
  services/         BLE engine, API client, repos, config, network
  models/           Data classes (API + session JSON)
  router/           GoRouter
  utils/            Helpers, logging, formatters
  constants/        App-wide literals
  design_system/    Shared tokens + reusable components
```

**Flow:** `screens → providers → services → models`

Server and web live in sibling repos — not in this project.

See [ARCHITECTURE.md](ARCHITECTURE.md) for data flow and folder details.
