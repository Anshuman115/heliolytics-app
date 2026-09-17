# Heliolytics App

Flutter phone client for a personal wearable-health system. It pairs with a strap,
uploads raw bytes to your Go server and displays the parsed results.

Source review: 7 September 2026. Describes the local code, not an installed-app or deployment check.

## How the product fits together

| Repo | Responsibility |
|---|---|
| Heliolytics_App | Bluetooth, onboarding, sync, mobile screens |
| Heliolytics | Historical health parsing, storage, summaries and API |
| Heliolytics_Web | Server-side metric reads and browser dashboard |

The app fetches fourteen band data types. Go owns their historical health parsing.
Flutter decodes transport framing and expands API responses for display; it does
not calculate the backend recovery score.

## What you can use

- Home: sleep, recovery and strain rings, daily insight, activities and seven health tiles.
- Health: baseline, live HR access, stress and metric detail views.
- Activity: workouts, automatic sessions and detail charts with HR zones.
- More: device status, cloud settings, alerts, diagnostics, logs and About.
- Setup: profile, Bluetooth permissions, scan, auth key, connection and backfill choice.

Sleep detail opens from Home or the metric route. `SleepHubScreen` exists in source
but is not a tab in the current shell. AI, journaling and configurable personal
goals are not implemented.

## Read the code

[Architecture](docs/local/ARCHITECTURE.md) maps screens, providers and services.

| Feature guide | Read for |
|---|---|
| [BLE sync](docs/features/ble-sync.md) | Coverage, fetch windows, raw uploads |
| [Home and rings](docs/features/home-and-rings.md) | Navigation, day bundles, cache, health tiles |
| [Sleep](docs/features/sleep.md) | Night selection, stages and naps |
| [Activity](docs/features/activity.md) | History and workout detail |
| [Band alerts](docs/features/band-alerts.md) | Call/app forwarding and vibration patterns |
| [Settings and device](docs/features/settings-and-device.md) | Setup, credentials, profile and logs |

## Local storage

Credentials and profile use platform secure storage. Closed-day server responses
are cached in Hive and SharedPreferences. Session metadata and diagnostic logs
also remain on-device; user-triggered raw dumps are separate files.
The server owns sync coverage. See [privacy](docs/local/PRIVACY.md) for the full distinction.

## Build instructions

Use the Flutter/Dart requirements in `pubspec.yaml` and select a connected device:

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

For a personal APK, copy `build.env.example` to private `build.env`, configure it,
and use `tool/build_apk.sh`. Build-time signing credentials are appropriate only
for your personal distribution. A public build should be configured in-app.

```sh
flutter build appbundle --release
```

These are commands for future use; this documentation update did not build or run
the app. A source review does not prove Play Store or device behavior.

Engineering rules: [docs/local/AGENTS.md](docs/local/AGENTS.md), [CLAUDE.md](CLAUDE.md).
[Apache License 2.0](LICENSE).
