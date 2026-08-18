# Feature — Activity

The Activity tab: workouts the user started deliberately, plus auto-detected
sessions the strap noticed on its own. Drill in for a per-workout HR chart and
time-in-zone breakdown.

## Two kinds of session

| Kind | Type code | Meaning |
|---|---|---|
| **Workout** | `0x05` (summary, protobuf) + `0x06` (per-second HR/cadence detail) | User pressed start on the strap |
| **Auto session** | Derived from `0x01` minute records | Sustained elevated HR, intensity, and movement without a manual workout |

Both are produced server-side and land in `activityHistoryProvider`
(`providers/activity_history_provider.dart`) as separate lists (`workouts`,
`activitySessions`). Sport names come from `utils/sport_labels.dart`.

`activityHistoryProvider` bulk-fetches roughly 90 days, session-cached only and
not disk-cached, to populate the chronological activity feed. The selected day's
Strain and summary metrics come from `dayBundleProvider`. See
[home-and-rings.md](home-and-rings.md) for why the bounded history request is an
exception to the normal one-day fetch pattern.

## Screens

- `ActivityHubScreen` — date navigation, Strain hero, daily summary, and a
  combined chronological activity feed
- `ActivityDetail Screen` (`activity_detail_screen.dart`) — one session: summary
  stats, HR chart, zone bars, driven by `ActivityDetailPayload`

## HR zones

`utils/hr_zones.dart` computes time-in-zone from per-second HR samples. The standard
rest + 5-zone model, each zone a fraction of max HR:

```dart
const List<double> hrZoneLowerFractions = [0.0, 0.5, 0.6, 0.7, 0.8, 0.9];
const int defaultMaxHrFallback = 190;
```

Zone `i` spans `[fraction[i], fraction[i+1])` of max HR; zone 5 is open-ended.

### Dwell accounting

Time is attributed per sample, not per row, with two guards:

- `_maxGapSeconds = 120` — caps dwell for any one sample, so a BLE gap doesn't
  credit an hour to whatever zone was last seen
- `_tailSeconds = 60` — nominal dwell for the final sample, which has no successor

### Max HR fallback

`defaultMaxHrFallback = 190` is used whenever a real max HR isn't supplied. It's a
placeholder, not the user's measured max. **Zones read wrong for anyone whose true
max differs materially.** A measured or profile max-HR source is still an open item.

`HrZoneBars` renders highest zone first (5 → 0), each row showing bpm range,
percentage, duration, and a proportional bar.

## Key files

| File | Role |
|---|---|
| `screens/activity_hub_screen.dart` | Date-aware Activity overview |
| `widgets/activity/activity_overview_body.dart` | Strain summary and feed composition |
| `widgets/activity/activity_feed_item.dart` | Workout/session feed adapter |
| `screens/activity_detail_screen.dart` | Single-session detail |
| `widgets/hr_zone_bars.dart` | Zone rows |
| `widgets/activity_row.dart` | List row |
| `utils/hr_zones.dart` | Zone math |
| `utils/sport_labels.dart` | Sport code → name |
| `services/ble/parsers/workout_parser.dart` | Workout framing (fetch-side) |
| `services/ble/parsers/activity_parser.dart` | Activity framing (fetch-side) |
| `models/activity_detail_payload.dart` | Detail view model |

> The two parsers under `services/ble/parsers/` handle **fetch framing** (record
> striding, page boundaries), not health interpretation. Health parsing is the
> server's job — see [ble-sync.md](ble-sync.md).
