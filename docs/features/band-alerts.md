# Feature — Band alerts

Forwards phone events (incoming calls, allowed app notifications) to the strap so it
vibrates. The strap has no display: an alert is **felt, not read**.

Shipped in v6. One-way only — phone → strap. Inbound dismiss/mute/reject is ignored.

Its own dedicated Settings screen (`BandAlertsSettingsScreen`, Settings →
Band Alerts) — previously an inline card on the Settings hub itself, now a
full screen reached via `/settings/band-alerts` (see
[settings-and-device.md](settings-and-device.md) for the current Settings
structure). All the state/logic below is unchanged, only the container
moved.

## Vocabulary

| Term | Meaning |
|---|---|
| **Band alert** | A vibration on the strap triggered by a phone-side event |
| **Alert forwarding** | Phone listens for OS events, sends them over BLE |
| **Band alerts mode** | Persistent BLE session (foreground service) that does the forwarding. Settings toggle. Off by default |
| **App allowlist** | Only apps the user explicitly allowed produce alerts. Starts empty |
| **Readiness** | Gate before the mode can be enabled: OS permissions granted, **and** either ≥1 allowed app or an explicit "calls only" choice |
| **Motor proof** | Find-device buzz on encrypted endpoint `0x001a` (`0x03` start / `0x06` stop). The Settings "Test vibration" button |
| **Band session** | The one shared `BandLink`. Sync, live HR, and alerts all borrow it |

## Session contention

`BandSessionProvider` is a mutex. **While band alerts mode is active, sync and live
HR are blocked** — the user must toggle alerts off first. This is deliberate: the
alerts foreground service holds the link open so alerts fire instantly, and a sync
would need to tear it down.

Cold connect costs a BLE connect + auth (a few seconds). Test vibration keeps the
session warm while you stay in Settings, then closes on exit or after 2 min idle.

## Enable sequence

`BandAlertsInitService.run()` (`services/ble/band_alerts_init.dart`), after BLE auth:

1. `ZeppServiceRegistry.requestServices(link)` — negotiate the strap's service list
2. `NotificationChannelInit.initialize(link)` — returns `NotificationCaps` (defaults `v4`)
3. If `forwardCalls`: `PhonePairService.initialize(link, bluetoothName:)` — ZeppOS
   phone pairing on `0x000b`, using the phone's Bluetooth adapter name (falls back
   to `"Heliolytics"`)
4. `VibrationPatternService` — push patterns to endpoint `0x0018`

Each step is spaced by `bandAlertsInitStepDelayMs`. Any failure aborts with
`success: false`.

## Vibration patterns

Endpoint `0x0018`, encrypted. A pattern is a type + an on/off millisecond list.

Defaults (`vibration_pattern_service.dart`):

| Type | Pattern (ms) |
|---|---|
| `vibrationTypeAppAlerts` | `[300, 600]` |
| `vibrationTypeIncomingCall` | `[300, 200, 600, 2000]` |

**v6 added user-editable patterns** — `band_alerts_call_pattern_screen.dart` and
`band_alerts_app_pattern_screen.dart`, backed by `vibration_pattern_form.dart` and
persisted via `band_alerts_call_pattern_storage.dart` /
`band_alerts_app_patterns_storage.dart`. `testBuzz` plays a pattern immediately
(byte 4 = 1) so the user can feel an edit before saving.

## Call forwarding

Sub-toggle under band alerts, on by default when the mode is enabled. Android-side
detection is `WhatsAppCallDetector.kt`, which reads `notification.category` and
compares against `Notification.CATEGORY_CALL`.

**Call-end payloads are mandatory.** When a call is answered, rejected, or missed the
app must send the end payload or the strap keeps vibrating.

## Disconnect behavior

If BLE drops while the mode is active, the app **stops retrying** and notifies the
user. Alerts stay dead until the user toggles the mode off and on. This is
intentional — silent auto-reconnect loops drained the battery and hid failures.

If connect fails, the app warns that the official Zepp app may be holding the BLE
connection (the two coexist; only one can hold the link).

## Scope

In: incoming calls + allowlisted app notifications.
Out (v1): SMS-only, alarms, goals, idle alerts, reminders, strap-initiated actions.

## Key files

| File | Role |
|---|---|
| `providers/band_alerts_provider.dart` | Mode state + readiness |
| `providers/band_alerts_forwarder.dart` | OS event → strap payload |
| `providers/band_session_provider.dart` | The link mutex |
| `services/ble/band_alerts_init.dart` | Enable sequence |
| `services/ble/zepp/vibration_pattern_service.dart` | `0x0018` patterns |
| `services/ble/zepp/phone_pair_service.dart` | `0x000b` pairing |
| `services/ble/zepp/zepp_service_registry.dart` | Service negotiation |
| `services/band_alerts/band_alerts_permissions.dart` | OS permission checks |
| `android/.../WhatsAppCallDetector.kt` | Call detection |

## Protocol ground truth

Gadgetbridge-compatible Huami/ZeppOS protocol. The official Zepp app does not do
alert forwarding for the Helio Strap, so there is no first-party behavior to mirror.
