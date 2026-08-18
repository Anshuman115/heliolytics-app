# Feature — Sleep

The Sleep tab: a hero summary for whichever day is currently selected (via
the same top-bar day nav as Home). Drill into that night for a hypnogram
and stage breakdown.

## Data source

`dayBundleProvider(dayKey)` → `DayBundle.sleep`, the full list of sleep
entries for that one day (main sleep + naps), parsed **server-side** from
strap type code `0x48` (sleep session blobs, including naps and stage
log). The phone never decodes sleep bytes. See
[home-and-rings.md](home-and-rings.md) for the per-day fetch/cache model
this and every other screen now shares.

Each session carries `startedAt`, `totalMins`, `isNap`, stage minutes, and a
score. `DayBundle.mainSleep` picks the highest-scored non-nap entry;
`DayBundle.naps` filters to naps only.

## Screen composition

`SleepHubScreen` (`screens/sleep_hub_screen.dart`) — a `ConsumerWidget`
watching `dayBundleProvider(selectedDayKeyProvider ?? todayDayKey())`,
wrapped in a `RefreshIndicator` that invalidates that one provider entry.
Shows only the selected day:

| Widget | Shows |
|---|---|
| `SleepHero` | The selected night — duration, score, stage bars, hypnogram |
| `SleepPerformanceBars` | Tiered bars vs. `neededMins` (default 480) |
| `SleepHypnogramChart` | Stepped stage timeline for that night |
| `SleepStageBar` / `SleepStageRow` | Per-stage duration + share |

**This is a rescope** — earlier versions also showed a multi-night
consistency chart (`SleepConsistencyChart`, a clock-axis bar chart across
the last 7 nights) and a scrollable night list (`SleepNightList`). Both
needed multiple days of data at once, which conflicts with the app's
per-day fetch model (see [home-and-rings.md](home-and-rings.md)) — rather
than add a bulk-fetch exception for this screen, both were dropped and both
widget files deleted. If a multi-night view returns, it'll need the same
kind of deliberate bounded-fetch exception `ActivityHubScreen` uses.

## Key files

| File | Role |
|---|---|
| `screens/sleep_hub_screen.dart` | Tab, single selected day |
| `widgets/sleep_hypnogram_chart.dart` | Stepped stage timeline |
| `widgets/sleep_hypnogram_painter.dart` | Timeline grid, fill, and stage path |
| `widgets/sleep_performance_bars.dart` | Tiered performance bars |
| `widgets/sleep_hero.dart` | Selected-night summary, takes a `DayBundle` |
| `widgets/sleep_metric_body.dart` | Sleep detail-screen body, takes a `DayBundle` |
| `models/sleep_stage.dart` | Stage enum |

The `0x48` byte layout and the offline-replay method used to validate sleep parsing
against ground truth are documented in notes kept outside this repo.
