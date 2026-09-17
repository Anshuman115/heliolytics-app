# Home, navigation and data loading

Source review: 7 September 2026. Describes the local code, not an installed-app or deployment check.

## Current tabs

| Tab | Screen |
|---|---|
| Home | `HomeScreen` |
| Health | `HealthHubScreen` |
| Activity | `ActivityHubScreen` |
| More | `SettingsHubScreen` |

`HelioShell` retains these pages in an `IndexedStack`. On its first frame it asks
the sync orchestrator to auto-connect. Sleep detail is reached from Home and the
metric-detail route; `SleepHubScreen` is not registered as a tab or route.

## Home content

Sleep, recovery and strain rings open the corresponding metric detail. The daily
insight uses fixed rules/text in `home_daily_insight.dart`, not AI.
The page includes connection/cloud state, daily movement, sleep and activities.

`buildHomeHealthReadings` creates seven health tiles: HRV, resting HR, calories,
hours of sleep, sleep efficiency, average HR and time in bed. This is not an
11-tile grid. The API response can carry more fields than this visible selection.

## Opening a day

1. `selectedDayKeyProvider` supplies the selected date, otherwise today.
2. `dayBundleProvider(dayKey)` checks the closed-day Hive cache.
3. On a miss, `MetricsApiClient.fetchDayBundle` starts four requests for that day:
   daily metrics, sleep, workouts and auto sessions.
4. The bundle completes as one unit. Auth, timeout or decoding failures propagate.
   Only a 404 from an explicitly optional list may become an empty list.
5. A successful closed-day bundle is stored. Today's bundle is not stored on disk.

`dailyHealthScoresProvider` separately fetches the health-score fields used by
Home. Closed-day responses use SharedPreferences.

A cached past day is a reusable copy, not immutable history. Delayed uploads can
change it. Today can remain in Riverpod memory; selecting it is not a guarantee
that a fresh network request occurs on every build.

## Opening a detail or history view

`detailMetricsProvider(dayKey)` fetches HR, vital series and temperature lazily,
then keeps them in memory. Revisiting a screen can reuse that provider; it does
not necessarily refetch each time the screen opens.

`activityHistoryProvider` reads bounded multi-day workout and automatic-session
history. Metric trend providers fetch daily rows over bounded ranges. These are
intentional exceptions to the usual single-day view.

Home avoids the heavy detail requests. It still makes a separate health-score
request; “one day” does not mean “one HTTP call.”

## Refresh and storage

`HealthDataRefreshCoordinator` handles scoped day refresh/retry and the main
post-sync/configuration invalidations. Sync clears stored day bundles and health
scores because older days can change. Configuration replacement clears caches
before saving the new API values.

Hive initialization can recover a corrupt disposable cache. A schema marker
rejects old bundle formats. None of this changes server-authoritative coverage.

## Read next

- `lib/screens/home_screen.dart`: composition and ring navigation.
- `lib/providers/day_bundle_provider.dart`: cache/read path.
- `lib/providers/detail_metrics_provider.dart`: heavy series.
- `lib/providers/health_data_refresh_coordinator.dart`: actual invalidation list.
- [Sleep](sleep.md), [activity](activity.md), [settings](settings-and-device.md).
