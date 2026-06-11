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

Or APK:

```bash
flutter build apk --release
```

## API setup

1. Start the stack from the **Heliolytics** repo (`deploy/install.sh`)
2. App **Settings → Cloud API**:
   - **API URL:** your server HTTPS endpoint (or `http://LAN:8080` in debug)
   - **API key:** same as `HELIOLYTICS_SIGNING_SECRET` in `deploy/.env`

The app mints short-lived HMAC tokens — you never paste tokens manually.

## Security

- Strap **auth key** (first-time setup) is BLE-only — not sent to the API
- **API key** signs requests to your Heliolytics server
- Device lock (PIN/biometrics) required when screen lock is enabled on the phone

## Privacy

See [PRIVACY.md](PRIVACY.md) for Play Store / data handling summary.

## Layout

```
lib/core/ble/     Protocol, sync engine
lib/features/     Feature modules (data / domain / presentation)
lib/shared/       Shared widgets and providers
```

Server and web live in sibling repos — not in this project.
