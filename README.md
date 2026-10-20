# Heliolytics App

Flutter phone client for a personal wearable-health system. It pairs with a strap,
uploads raw bytes to your Go server and displays the parsed results.

## How the product fits together

| Repo | Responsibility |
|---|---|
| heliolytics-app | Bluetooth, onboarding, sync, mobile screens |
| heliolytics | Historical health parsing, storage, summaries and API |
| heliolytics-web | Server-side metric reads and browser dashboard |

The app fetches twelve band data types. Go owns their historical health parsing.
Flutter decodes transport framing and expands API responses for display; it does
not calculate the backend recovery score, readiness components or training load.

## What you can use

- Home: sleep, recovery and training-load rings, daily insight, activities and up to eight health tiles.
- Health: baseline, live HR access, stress and metric detail views.
- Activity: recorded workouts, heuristic auto-detected activities and detail charts with HR zones.
- More: device status, cloud settings, alerts, diagnostics, logs and About.
- Setup: profile, Bluetooth permissions, scan, auth key, connection and backfill choice.

Sleep detail opens from Home or the metric route. `SleepHubScreen` exists in source
but is not a tab in the current shell. AI, journaling and configurable personal
goals are not implemented.

## API access

Every data request is signed with the phone API key:

- Settings stores an HTTPS API origin and a `phone.<64 lowercase hex>` key in
  platform secure storage. Web and unknown kids are rejected before any request.
- Each request carries `X-Heliolytics-Auth` and `X-Heliolytics-Content-SHA256`.
  The HMAC covers method, escaped path, raw query, body hash and Content-Type.
- Plain HTTP is accepted only for loopback development hosts outside release builds.
- A 401 is reported with key and clock guidance. There is no automatic retry on a
  deterministic 4xx.

## Feature guides

The feature guides describe the current screens, providers, services, data flow and storage behavior.

| Feature guide | Read for |
|---|---|
| [BLE sync](docs/features/ble-sync.md) | Coverage, fetch windows, raw uploads |
| [Home and rings](docs/features/home-and-rings.md) | Navigation, day bundles, cache, health tiles |
| [Sleep](docs/features/sleep.md) | Main session, naps, stages and truncation |
| [Activity](docs/features/activity.md) | Unified feed and activity detail |
| [Band alerts](docs/features/band-alerts.md) | Call/app forwarding and vibration patterns |
| [Settings and device](docs/features/settings-and-device.md) | Setup, API key, profile and logs |

## Local storage

Credentials and profile use platform secure storage. Closed-day server responses
are cached in Hive. Session metadata and diagnostic logs also remain on-device;
user-triggered raw dumps are separate files.
The server owns sync coverage. The local-only privacy notes describe the full distinction.

## Build instructions

Use the Flutter/Dart requirements in `pubspec.yaml` and select a connected device:

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

For a personal build, copy `build.env.example` to private `build.env`, set only the
API origin and use `tool/build_apk.sh`. The API key is never a build input: it is
entered once in Settings and kept in secure storage.

```sh
flutter build appbundle --release
```

Validation: the app was not built or run for this revision. A source review does not prove Play Store or device behavior.

[Apache License 2.0](LICENSE).
