# Home, navigation and data loading

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

Sleep, recovery and training-load rings open the corresponding metric detail. The
load ring shows Banister TRIMP, never a fabricated strain percentage. The daily
insight uses fixed rules/text in `home_daily_insight.dart`, not AI.
The page includes connection/cloud state, daily movement, sleep and activities.

`buildHomeHealthReadings` creates health tiles from the selected day's bundle only:
HRV, resting HR, measured SpO2 (only when samples exist), workout calories, hours
of sleep, sleep efficiency, average HR and time in bed. Energy is labelled as
workout calories, not total daily burn. Missing values show as unavailable rather
than zero.

## Opening a day

1. `selectedDayKeyProvider` supplies the selected IST date, otherwise today.
2. `dayBundleProvider(dayKey)` checks the closed-day Hive cache.
3. On a miss, `MetricsApiClient.fetchDayBundle` issues exactly three requests for
   that day: `/api/daily-metrics`, `/api/sleep` and `/api/activities`.
4. The bundle completes as one unit. Auth, timeout, 404, 422, 5xx and decoding
   failures propagate. There is no optional-route swallowing.
5. A successful closed-day bundle is stored. Today's bundle is not stored on disk.

All day keys are IST calendar days. `todayDayKey`, the closed-day check, the date
picker limit, day stepping and the day labels use the IST clock, never the phone
timezone. Sample times display on the IST wall clock; stored and wire instants
stay UTC.

A day the server does not support has a null `DayMetric`, which the UI shows as no
data. The app never synthesizes `steps: 0`.

A cached past day is a reusable copy, not immutable history. Delayed uploads can
change it. Today can remain in Riverpod memory; selecting it is not a guarantee
that a fresh network request occurs on every build.

## Opening a detail or history view

`detailMetricsProvider(dayKey)` fetches minute HR, the four supported compact
series (`hrv`, `stress`, `resp`, `spo2`) and temperature lazily, then keeps them in
memory. Sample windows are capped at 31 days and summary windows at 366; a range
above the cap is refused locally instead of relying on a 400.

`activityHistoryProvider` makes one `/api/activities` call over a bounded
90-day window and partitions recorded workouts from auto-detected activities
without hiding request errors. Metric trend providers fetch daily rows over bounded
IST ranges.

Home makes three requests for the selected day and nothing else: there is no
second health-score request and no separate scores cache.

## Refresh and storage

`HealthDataRefreshCoordinator` handles scoped day refresh/retry and the main
post-sync/configuration invalidations. Sync clears stored day bundles, because
older days can change. Configuration replacement clears caches before saving the
new API values.

Hive initialization can recover a corrupt disposable cache. An entry that fails
to decode is a cache miss rather than rehydrated data; an HTTP failure is never
written as a successful empty bundle. None of this changes server-authoritative
coverage.

## Related code and behavior

- `lib/screens/home_screen.dart`: composition and ring navigation.
- `lib/providers/day_bundle_provider.dart`: cache/read path.
- `lib/providers/detail_metrics_provider.dart`: heavy series.
- `lib/providers/health_data_refresh_coordinator.dart`: actual invalidation list.
- [Sleep](sleep.md), [activity](activity.md), [settings](settings-and-device.md).

Validation: not run for this revision.
