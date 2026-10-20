# Sleep

## How to reach it

Tap the Sleep ring on Home. The generic metric route renders the sleep body.
`SleepHubScreen` remains in source but is not in the router or main shell.
There is no current dedicated Sleep tab or multi-night consistency chart.

## Data

`dayBundleProvider(dayKey)` supplies a `SleepDay` built by Go from band type
`0x48`. The server decides which non-nap session is `main`; the app renders that
session verbatim and never reselects the highest score. `naps` keeps every nap
separately, and a nap score may be null without becoming zero.

Each session carries start and end instants, stage minutes, an optional score,
`stagesTruncated` and half-open stage intervals (`end` is exclusive). The hypnogram
renders those intervals directly with no added minute and no overlap. When
`stagesTruncated` is true the UI says the stage timeline covers only part of the
night.

Daily sleep minutes come from the server rollup of non-overlapping sessions, so the
daily total can differ from the main session alone. Time in bed and efficiency are
server fields; the app displays `sleepEfficiencyPct` and does not recompute it from
a possibly truncated stage list.

Measured SpO2 during sleep comes only from real `0x25` samples inside the main and
nap windows. Type `0x26` is raw sleep-breathing placeholder data and is never
shown as oxygen. Physical SpO2 verification on hardware is still pending.

## UI pieces

- `sleep_metric_body.dart`: composes the sleep detail sections.
- `sleep_hero.dart`: night summary.
- `sleep_hypnogram_chart.dart` and painter: stage timeline.
- `sleep_stage_bar.dart`, `sleep_stage_row.dart`: stage proportions.
- `sleep_naps_section.dart`: naps with the truncation caveat.
- `sleep_performance_bars.dart`: comparisons; its default sleep target is 480 minutes.

A configurable sleep target and bounded multi-night regularity view would be new
features. Existing values and charts are not personalized goal settings.

See [home and data loading](home-and-rings.md) for caching, refresh and the selected day.

Validation: not run for this revision.
