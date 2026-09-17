# Sleep

Source review: 7 September 2026. Describes the local code, not an installed-app or deployment check.

## How to reach it

Tap the Sleep ring on Home. The generic metric route renders the sleep body.
`SleepHubScreen` remains in source but is not in the router or main shell.
There is no current dedicated Sleep tab or multi-night consistency chart.

## Data

`dayBundleProvider(dayKey)` supplies sleep sessions parsed by Go from band type
`0x48`. Each session has start time, duration, stage minutes, score and nap status.
`DayBundle.mainSleep` selects the highest-scored non-nap session; `naps` keeps naps
separate. Main sleep is not the sum of every session on that date.

The hypnogram uses the stage start/end timestamps from the server. Sleep minutes
and elapsed time in bed differ because wake minutes also occupy time. The backend
health-score response calculates time in bed and efficiency from the selected
main session.

## UI pieces

- `sleep_metric_body.dart`: composes the sleep detail sections.
- `sleep_hero.dart`: night summary.
- `sleep_hypnogram_chart.dart` and painter: stage timeline.
- `sleep_stage_bar.dart`, `sleep_stage_row.dart`: stage proportions.
- `sleep_naps_section.dart`: naps.
- `sleep_performance_bars.dart`: comparisons; its default sleep target is 480 minutes.

A configurable sleep target and bounded multi-night regularity view would be new
features. Existing values and charts are not personalized goal settings.

See [home and data loading](home-and-rings.md) for caching, refresh and the selected day.
