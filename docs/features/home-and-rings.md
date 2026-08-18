# Feature — Home & rings

The landing tab. Three equal rings (recovery / sleep / strain), a "my day"
strip, recent activities, and an 11-tile daily-health-scores grid — all for
one selected day.

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
progress across all tabs (backed by `syncStatusProvider`, not day data);
`AppLifecycleScope` handles background/foreground, and also checks Bluetooth
state on resume — if it's off and a strap is paired, a dialog prompts the
user to turn it on.

## Data source: per-day, not bulk

The app used to fetch a rolling bulk window (10+ days at once) into one
in-memory `liveHealthProvider` snapshot on every cold start. That's gone —
**everything now fetches one day at a time**, cached to disk once that day
is closed:

- **`dayBundleProvider(dayKey)`** (`providers/day_bundle_provider.dart`) — a
  `FutureProvider.family<DayBundle, String>`. For a **final** day
  (`dayKey < today`, via `isFinalDayKey()` in `utils/day_key.dart`), checks
  `DailyBundleCacheStorage` first and returns the cached result with zero
  network calls if present. For **today**, always fetches fresh — a day in
  progress is never cached. On any cache miss, calls
  `MetricsApiClient.fetchDayBundle(dayKey)` (explicit `from=dayKey&to=dayKey`,
  not the old rolling-window `_range()`), then writes the result to cache
  if the day was final.
- **`DailyBundleCacheStorage`** (`services/cache/daily_bundle_cache_storage.dart`)
  stores one JSON-encoded `DayBundle` per `dayKey` in a Hive box. This is the
  one deliberate exception to
  "no on-device persistence" (see CLAUDE.md Code Style) — it's caching the
  server's already-parsed response for offline/fast display, not parsing
  health data on-device. A box-level schema marker performs a one-time purge
  of bundles written before atomic optional-endpoint handling. Routine cache
  clears preserve that marker, so the migration does not repeat each launch.
- **`selectedDayKeyProvider`** (`providers/selected_day_provider.dart`) — a
  plain `StateProvider<String?>`, defaulting to `todayDayKey()`.
  `shiftSelectedDay(ref, delta)` just increments/decrements the date string;
  there's no hard lower bound (no "earliest data" signal exists from the
  server), so paging backward always works — a day with nothing synced just
  renders empty.

`DayBundle` (`models/day_bundle.dart`) holds `day: DayMetric`,
`sleep: List<SleepMetric>` (main sleep + naps for that day — not filtered
to just the main sleep, since detail screens need naps too), `workouts`,
`activitySessions`, plus `mainSleep`/`naps` derived getters and an
`isFinal` getter.

The four bundle reads start in parallel but complete as one unit. A `401`,
timeout, malformed response, or model-decoding failure aborts the bundle, and
`dayBundleProvider` writes nothing to the historical cache. Only a `404` from
the explicitly optional sleep, workout, or automatic-activity list maps to an
empty list. Other failures remain failures instead of becoming false "no data"
states.

### Why this changed

Bulk-fetching a new user's full history in one call is expensive
server-side. Per-day fetch-on-demand means the server only ever answers for
the day actually being viewed, and once a day is closed its data never gets
asked for again.

### The two-tier metrics split (still true)

- **`dayBundleProvider`** — light per-day rollups. Home, Sleep, and Activity
  detail screens use this.
- **`detailMetricsProvider`** (`providers/detail_metrics_provider.dart`,
  extracted from the retired bulk provider) — heavy per-minute datasets
  (`series`, continuous `heartRate`, `temperature`). Loads **lazily on
  first watch**, cached for the session, used only by health-monitor and
  metric-detail screens. Not per-day-cached to disk — refetched each time a
  detail screen opens.
- **`metricTrendProvider`** — bounded daily rollups for the real week, month,
  and six-month controls on metric trend screens. Period navigation remains
  capped at 180 days so trend views do not pull unbounded history.

Detail and trend providers propagate network and decoding failures. An empty
list therefore means the server successfully returned no rows; it is never a
fallback for an unsuccessful request.

Keeping them apart is why Home doesn't pull megabytes of minute data.
`HealthDataRefreshCoordinator` is the single provider-layer owner of refresh
and invalidation. After a sync commits it clears stored day bundles and health
scores, then invalidates day bundles, daily health scores, activity history,
detail metrics, trends, and sync status. An actual Cloud API URL or signing-key
change clears both disk caches before saving the new configuration and
invalidating the same state. Screen pull-to-refresh and retry callbacks use the
coordinator's scoped per-day operations. Historical days cannot be treated as
immutable because a chosen first-sync range or delayed strap upload can add
older data.

### The one deliberate exception: Activity hub

`ActivityHubScreen` shows a tabbed, multi-day history list (workouts / auto
sessions) — inherently needs a range, not one day. `activityHistoryProvider`
(`providers/activity_history_provider.dart`) does a bounded bulk fetch
(~90 days, the existing server default), **session-cached only, not
disk-cached** — refetches each time the screen opens. Deliberately kept out
of the per-day disk cache to avoid partial-merge risk against `DayBundle`
entries that may not exist yet for unvisited days.

## Composition

`HomeScreen.build` watches `dayBundleProvider(selectedDayKeyProvider ??
todayDayKey())`, `apiConfiguredProvider`, and `syncOrchestratorProvider`,
then assembles:

| Widget | Shows |
|---|---|
| `HelioTopBar` | Date nav, sync button, battery |
| `HomePrimaryRings` | Recovery, sleep, strain — three equal rings |
| `HomeStatusRow` | Connection / cloud state |
| `HomeMyDaySection` | Steps, calories, HR summary |
| `HomeActivitiesSection` | Recent workouts / auto sessions, sourced from `DayBundle` |
| `HomeHealthScoresSection` | 11-tile daily-health-scores grid (below the fold) |

States: `HelioLoading` while pending, `ErrorView` on failure, `HelioEmptyState` when
a day has no data, `HelioCloudBanner` when the API isn't configured.

### `HomeHealthScoresSection`

Loads independently of the rest of the screen (its own `AsyncValue`,
doesn't block the rings/status/activities above it), watching both
`dayBundleProvider(dayKey)` and `dailyHealthScoresProvider(dayKey)`
(`providers/daily_health_scores_provider.dart` — same cache-or-fetch shape
as `dayBundleProvider`, targeting `GET /api/v1/daily-health-scores`).
`buildHomeHealthReadings()`
(`utils/health_monitor_readings.dart`) assembles all 11 tiles: HRV and RHR
reuse the existing baseline-assessment machinery (colored tier chips judged
against your own recent history — see `HealthMonitorScreen`); the 7 fields
with no backend data yet (VO2 Max, calories, avg HR, sleep efficiency/debt/
consistency/needed) render as plain `—` via `MetricAssessment.noData`,
same as any other not-yet-synced metric. An empty `days` list is a valid
"no data yet" result. Authentication, endpoint, and payload failures remain
visible as errors.

Baseline history for HRV/RHR's colored assessment comes from whatever final
days already happen to be sitting in `DailyBundleCacheStorage` — no
dedicated bulk fetch just to seed it. A fresh install shows raw numbers
with no tier judgement at first; it fills in naturally as the user visits
more days.

## Recovery score

Prefers the strap's own daily readiness (type code `0x39`). Falls back to the
server's computed score when the device didn't report one. Both arrive pre-computed
in the payload — the phone never calculates it.

## Rules that bite here

- No logic in `build()` — derive in the provider.
- `ref.watch` in `build`, `ref.read` in callbacks.
- Rings/colors come from `HelioMetricColors`; spacing from `HelioSpacing`.
- `build()` ≤ 40 lines — `HomeScreen` delegates each section to its own widget file.

## Key files

| File | Role |
|---|---|
| `screens/home_screen.dart` | Tab composition |
| `screens/helio_shell.dart` | Nav shell + auto-connect |
| `providers/day_bundle_provider.dart` | Per-day cache-or-fetch |
| `providers/daily_health_scores_provider.dart` | Health-scores cache-or-fetch |
| `providers/detail_metrics_provider.dart` | Lazy per-minute datasets |
| `providers/health_data_refresh_coordinator.dart` | Scoped refresh and full invalidation |
| `providers/selected_day_provider.dart` | Day selection |
| `services/cache/daily_bundle_cache_storage.dart` | Disk cache, final days |
| `services/cache/daily_health_scores_cache_storage.dart` | Disk cache, health scores |
| `services/network/metrics_api_transport.dart` | Typed HTTP status, JSON decoding, one-time auth retry |
| `utils/day_key.dart` | `todayDayKey()` / `isFinalDayKey()` |
| `widgets/home_primary_rings.dart` | The three rings |
| `widgets/home_my_day_section.dart` | Day stats |
| `widgets/home_activities_section.dart` | Activity list |
| `widgets/home_health_scores_section.dart` | 11-tile health-scores grid |
