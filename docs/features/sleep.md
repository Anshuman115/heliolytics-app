# Feature — Sleep

The Sleep tab: a hero summary for the latest night, a consistency chart across
recent nights, and a scrollable night list. Drill into any night for a hypnogram
and stage breakdown.

## Data source

`liveHealthProvider` → `CloudMetricsSnapshot.sleep`, a list of sessions parsed
**server-side** from strap type code `0x48` (sleep session blobs) plus `0x4E`
(segments / nap log). The phone never decodes sleep bytes.

Each session carries `startedAt`, `totalMins`, `isNap`, stage minutes, and a score.

## Screen composition

`SleepHubScreen` (`screens/sleep_hub_screen.dart`) — a `ConsumerWidget` watching
`liveHealthProvider`, wrapped in a `RefreshIndicator` that calls `reload()`:

| Widget | Shows |
|---|---|
| `SleepHero` | Latest night — duration, score, headline stages |
| `SleepConsistencyChart` | Bed→wake bars across recent nights |
| `SleepNightList` | Scrollable history, taps into detail |
| `SleepPerformanceBars` | Tiered bars vs. `neededMins` (default 480) |
| `SleepHypnogramChart` | Stepped stage timeline for one night |
| `SleepStageBar` / `SleepStageRow` | Per-stage duration + share |

## Consistency chart

`widgets/sleep_consistency_chart.dart` — a `CustomPainter`, one vertical bar per
night spanning bedtime → wake on a **shared clock axis**, so drift is visible as
horizontal misalignment.

The non-obvious part is the axis. Nights cross midnight, so wall-clock time can't be
plotted directly. Everything is normalized to **minutes since 18:00**:

```dart
double _minsSince6pm(DateTime t) {
  final anchor = DateTime(t.year, t.month, t.day, 18);
  var diff = t.difference(anchor).inMinutes.toDouble();
  if (diff < 0) diff += 24 * 60; // morning wake belongs to prior evening
  return diff;
}
```

A 02:00 wake becomes 8 h — continuous past midnight, comparable across nights.
The 6 PM anchor is why a wake time before 18:00 gets pushed forward a full day
rather than going negative.

The domain snaps to whole 3-hour ticks (`_tick = 180.0`) around the data range, so
bar heights are proportional and gridlines land on labelled clock times
(`9PM`, `12AM`, `3AM`…). Layout: 40 px left gutter for axis labels, 22 px bottom for
day labels. The newest night is `HelioColors.sleepRem`; the rest `ringTrack`.

Input comes from `_consistencySpans()` in the screen — main sleeps only (`!isNap`),
sorted ascending, last 7.

Renders nothing below 2 nights (a consistency chart of one night is meaningless).

## Key files

| File | Role |
|---|---|
| `screens/sleep_hub_screen.dart` | Tab + span selection |
| `widgets/sleep_consistency_chart.dart` | Clock-axis painter |
| `widgets/sleep_hypnogram_chart.dart` | Stepped stage timeline |
| `widgets/sleep_performance_bars.dart` | Tiered performance bars |
| `widgets/sleep_hero.dart` | Latest-night summary |
| `widgets/sleep_night_list.dart` | History list |
| `models/sleep_stage.dart` | Stage enum |

The `0x48` byte layout and the offline-replay method used to validate sleep parsing
against ground truth are documented in notes kept outside this repo.
