# Privacy — Heliolytics App

Heliolytics is a personal health tool. Data stays under your control.

## What we collect

- Health metrics from your Helio Strap via Bluetooth (heart rate, steps, sleep, SpO₂, etc.)
- Device pairing key (stored on-device only, used for BLE)
- API server URL and API key (stored in encrypted storage on-device)

## Where data goes

- Raw sync uploads go **only** to the Heliolytics server **you configure**
- No third-party analytics or cloud backends are built into the app
- The app does not send data to the developer by default

## On-device storage

- Strap auth key and API credentials: Android EncryptedSharedPreferences / iOS Keychain (via `flutter_secure_storage`)
- Session metadata during sync: app documents directory on your phone

## Your choices

- You choose the API server URL and key
- You can delete app data by clearing app storage or uninstalling
- Device lock (PIN/biometrics) gates access when your phone has a screen lock enabled

## Contact

Maintained as a personal open-source project. Update this file with your contact email before Play Store submission.
