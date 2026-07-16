# Feature — Home & rings

The landing tab. Three equal rings (recovery / sleep / strain), a "my day" strip,
and recent activities — all for one selected day.

## Shell

`HelioShell` (`screens/helio_shell.dart`) hosts four tabs via `HelioBottomNav`:

| Tab | Screen |
|---|---|
| Home | `HomeScreen` |
| Sleep | `SleepHubScreen` |
| Activity | `ActivityHubScreen` |
| More | `SettingsHubScreen` |

On first frame the shell calls `scheduleAutoConnect()` on the sync orchestrator, so
opening the app tries to reach the strap without a tap. `HelioSyncStrip` shows sync
progress across all tabs; `AppLifecycleScope` handles background/foreground.

## Data source

Everything on Home reads `liveHealthProvider` — an `AsyncNotifier` holding a
`CloudMetricsSnapshot` fetched from the Go API. **No BLE reads on this path.** The
strap fills the server; the UI reads the server.

`selectedDayProvider` picks the day. Home is a pure projection of
`snapshot × selectedDay`.

### The two-tier metrics split

This is the important architectural bit:

- **`liveHealthProvider`** — light per-day rollups (`days`, `sleep`, `workouts`,
  `activities`). Home, Sleep, and Activity use only this.
- **`detailMetricsProvider`** — heavy per-minute datasets (`series`, continuous
  `heartRate`, `temperature`). Loads **lazily on first watch**, cached for the
  session, used only by health-monitor and metric-detail screens.

Keeping them apart is why Home doesn't pull megabytes of minute data. If you add a
minute-resolution widget to Home, you defeat this — put it behind a detail route
instead. Both are invalidated together after a sync commit.

## Composition

`HomeScreen.build` watches `liveHealthProvider`, `apiConfiguredProvider`, and
`syncOrchestratorProvider`, then assembles:

| Widget | Shows |
|---|---|
| `HelioTopBar` | Date nav, sync button, battery |
| `HomeStatusRow` | Connection / cloud state |
| `HomePrimaryRings` | Recovery, sleep, strain — three equal rings |
| `HomeMyDaySection` | Steps, calories, HR summary |
| `HomeActivitiesSection` | Recent workouts / auto sessions |

States: `HelioLoading` while pending, `ErrorView` on failure, `HelioEmptyState` when
a day has no data, `HelioCloudBanner` when the API isn't configured.

## Recovery score

Prefers the strap's own daily readiness (type code `0x39`). Falls back to the
server's computed score when the device didn't report one. Both arrive pre-computed
in the snapshot — the phone never calculates it.

## Rules that bite here

- No logic in `build()` — derive in the provider.
- `ref.watch` in `build`, `ref.read` in callbacks.
- Rings/colors come from `HelioMetricColors`; spacing from `HelioSpacing`.
- `build()` ≤ 40 lines — `HomeScreen` stays at 193 total by delegating each section
  to its own widget file.

## Key files

| File | Role |
|---|---|
| `screens/home_screen.dart` | Tab composition |
| `screens/helio_shell.dart` | Nav shell + auto-connect |
| `providers/live_health_provider.dart` | Snapshot + `DetailMetrics` |
| `providers/selected_day_provider.dart` | Day selection |
| `widgets/home_primary_rings.dart` | The three rings |
| `widgets/home_my_day_section.dart` | Day stats |
| `widgets/home_activities_section.dart` | Activity list |
