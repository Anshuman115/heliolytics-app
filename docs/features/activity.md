# Feature : Activity

The Activity tab: workouts the user started deliberately, plus auto-detected
activities the server inferred from minute movement. Drill in for a heart-rate
chart and time-in-zone breakdown.

## One activity shape, two kinds

| Kind | Source | Meaning |
|---|---|---|
| **workout** | `0x05` summary plus `0x06` per-second detail | User pressed start on the strap |
| **auto** | Server detection over `0x01` minute steps and HR | Sustained movement with no recorded workout |

`GET /api/v1/activities` returns one unified list. `ActivityMetric`
(`models/activity_metric.dart`) stores `kind`, `dayKey`, exact start and end,
`durationSec`, `sportType`, `sportName`, `calories`, `avgHr`, `maxHr`, `minHr`,
`steps` and `hasDetail`. Null statistics stay null and `hasDetail=false` means no
recorded workout detail, not that the activity is missing.

Auto activities use `sportType=0` and the server label `Walk` or `Run`. They are
explicitly heuristic, not vendor-recorded sports and not a diagnosis. The app does
not decode `0x3B` as activities.

`activityHistoryProvider` makes one 90-day `/activities` call, keeps the result in
the session only, and partitions by kind without replacing a request error with
empty maps. The selected day's summary and training load come from
`dayBundleProvider`. That bounded history request is the normal exception to the
one-day fetch pattern described in [home-and-rings.md](home-and-rings.md).

## Screens

- `ActivityHubScreen` : date navigation, training-load hero, daily summary, and a
  combined chronological feed that labels recorded and auto activities differently
- `ActivityDetailScreen` : one activity with summary stats, HR chart, zone bars and
  min/max/average HR, steps and calories when the server supplies them, driven by
  `ActivityDetailPayload`

The HR window is half-open `[startedAt, endedAt)`.

## Training load

Training load is Banister TRIMP from measured minute heart rate. The backend needs
a birth date and sex in the profile to estimate it; without them load is
unavailable rather than guessed. The Activity hero and the `load` metric page both
show TRIMP. PAI is a separate device score and is not relabelled as strain.

## HR zones

`utils/hr_zones.dart` computes time-in-zone from timestamped HR samples fetched for the day. The implemented
rest + 5-zone display model, each zone a fraction of max HR:

```dart
const List<double> hrZoneLowerFractions = [0.0, 0.5, 0.6, 0.7, 0.8, 0.9];
const int defaultMaxHrFallback = 190;
```

Zone `i` spans `[fraction[i], fraction[i+1])` of max HR; zone 5 is open-ended.

### Dwell accounting

Time is attributed per sample, not per row, with two guards:

- `_maxGapSeconds = 120` : caps dwell for any one sample, so a BLE gap doesn't
  credit an hour to whatever zone was last seen
- `_tailSeconds = 60` : nominal dwell for the final sample, which has no successor

### Max HR fallback

`defaultMaxHrFallback = 190` is used whenever a real max HR isn't supplied. It's a
placeholder, not the user's measured max. The activity detail supplies its recorded
session maximum when present; that is not necessarily a physiological maximum.
User-configurable maximum HR and zones are not implemented.

`HrZoneBars` renders highest zone first (5 → 0), each row showing bpm range,
percentage, duration, and a proportional bar.

## Key files

| File | Role |
|---|---|
| `screens/activity_hub_screen.dart` | Date-aware Activity overview |
| `widgets/activity/activity_overview_body.dart` | Load summary and feed composition |
| `widgets/activity/activity_feed_item.dart` | Unified activity feed adapter |
| `screens/activity_detail_screen.dart` | Single-activity detail |
| `widgets/hr_zone_bars.dart` | Zone rows |
| `widgets/activity_row.dart` | List row |
| `utils/hr_zones.dart` | Zone math |
| `utils/sport_labels.dart` | Sport code → name |
| `services/ble/parsers/workout_parser.dart` | Workout framing (fetch-side) |
| `services/ble/parsers/activity_parser.dart` | Activity framing (fetch-side) |
| `models/activity_metric.dart` | Unified activity model |

> The two parsers under `services/ble/parsers/` handle **fetch framing** (record
> striding, page boundaries), not health interpretation. Health parsing is the
> server's job : see [ble-sync.md](ble-sync.md).

Validation: not run for this revision.
