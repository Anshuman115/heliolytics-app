# Heliolytics

Flutter app that connects directly to the **Amazfit Helio Strap 2025** over BLE, extracts health data (raw binary), and stores it locally. No Zepp cloud involved after the initial auth key setup.

## What This App Does

1. Authenticates with the strap using a user-pasted auth key (ECDH + AES)
2. Fetches health data type codes over the Huami chunked BLE protocol
3. Saves raw `.bin` files per data type + session metadata JSON
4. Phase 2: parse and sync to a TimescaleDB backend (separate repo)

## Project Structure

```
lib/
  core/ble/        → BLE engine (fetch, auth, chunked protocol, parsers)
  features/        → UI (auth, scan, fetch, sessions)
```

Local-only artifacts (not in git): see `.gitignore`.

## Supported Hardware

- **Device:** Amazfit Helio Strap 2025 (ZeppOS 4.x)
- **Protocol:** Huami/ZeppOS BLE activity-fetch (Gadgetbridge-compatible)
- **Timezone:** Per-user; device tz byte `0x16` often means UTC+5:30

## Data Types (confirmed)

| Code | Name | Notes |
|------|------|-------|
| `0x01` | Activity (HR + steps + kind) | 8 B/min, round-relative time |
| `0x05` | Workout summary | protobuf |
| `0x13` | Stress (auto) | 4 B/min |
| `0x25` | SpO₂ spot | session-based |
| `0x2E` | Skin temperature | 8 B/min |
| `0x38` | Sleep respiratory rate | 8 B/min |
| `0x3A` | Resting HR | 6 B, absolute ts |
| `0x3D` | Max HR | 6 B, absolute ts |
| `0x48` | Sleep sessions | 594 B/session |
| `0x49` | HRV RMSSD | 6 B, absolute ts |

## Getting Started

1. Obtain a 32-character hex auth key for your strap (Zepp API / account tools)
2. Open the app, paste the auth key
3. Scan and select your Helio Strap, then tap **Connect** to run a fetch session
4. Session metadata is written to app-private storage (`session.json`, `types.json`)
