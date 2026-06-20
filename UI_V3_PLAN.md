# Heliolytics App UI v3 — Status

> **Branch:** `v3`
> **Goal:** Helio dark UI, auto strap connect/sync, health monitor grid, fixed sleep/recovery flows.

**Status:** Implemented. Presentation uses `design_system/` + layer-first folders. BLE/cloud logic unchanged.

**Reference UI:** dark canvas, hero score rings, health monitor grid, ALL-CAPS labels, insight cards, top date nav + battery, bottom tabs (Home · Sleep · Activity · More).

---

## Folder structure (current)

```
lib/
  main.dart
  app.dart
  router/app_router.dart
  screens/                       # 12 pages
    helio_shell.dart
    home_screen.dart
    sleep_hub_screen.dart
    activity_hub_screen.dart
    settings_hub_screen.dart
    health_monitor_screen.dart
    metric_detail_screen.dart
    activity_detail_screen.dart
    auth_key_screen.dart
    device_scan_screen.dart
    api_settings_screen.dart
  widgets/                       # Screen-specific sections + charts
  providers/                     # Riverpod (6 files)
    sync_orchestrator.dart
    live_health_provider.dart
    helio_nav_provider.dart
    selected_day_provider.dart
    cloud_sync_provider.dart
    api_config_form_provider.dart
  services/                      # BLE, API, repos (no UI)
  models/                        # API + session entities
  utils/                         # Logger, formatters, chart helpers
  constants/constants.dart
  design_system/
    tokens/
      helio_colors.dart
      helio_metric_colors.dart   # Chart / metric accent colors
      helio_spacing.dart         # Single spacing scale (4/8/12/16/24/32)
      helio_typography.dart
      helio_radii.dart
    theme/helio_theme.dart
    components/
      helio_surface_card.dart
      helio_score_ring.dart
      helio_section_header.dart
      helio_top_bar.dart
      helio_bottom_nav.dart
      helio_date_nav.dart
      helio_vital_tile.dart
      helio_monitor_panel.dart   # includes HelioMonitorPanel.forDay()
      helio_sync_strip.dart
      helio_insight_card.dart
      helio_empty_state.dart
      helio_loading.dart
      helio_text_field.dart
      helio_primary_button.dart
      helio_secondary_button.dart
      helio_metric_bar.dart
      helio_cloud_banner.dart
      helio_wordmark.dart
      helio_settings_tile.dart
```

**Removed (dead / duplicate):** `day_detail_screen`, `helio_week_strip`, `helio_status_card`, `home_monitor_panel`, `home_week_strip`, `day_series_section`, `AppSpacing`, `MetricColors` in utils.

---

## Design tokens

| Token | Value | Use |
|-------|-------|-----|
| `canvas` | `#000000` | Scaffold bg |
| `surface` | `#141414` | Cards |
| `surfaceElevated` | `#1C1C1E` | Nested cards |
| `border` | `white @ 10%` | Card stroke |
| `textPrimary` | `#FFFFFF` | Values |
| `textSecondary` | `#8E8E93` | Labels |
| `textMuted` | `#636366` | Hints |
| `recoveryLow/Mid/High` | red / yellow / green | Recovery ring |
| `sleepBlue` | `#0A84FF` | Sleep ring |
| `strainBlue` | `#64D2FF` | Activity ring |
| `optimalGreen` | `#30D158` | Monitor badges |
| Spacing | 4/8/12/16/24/32 | `HelioSpacing` xs–xxl |

Typography: ALL-CAPS labels for metric names. Large bold numbers for scores.

---

## Navigation

**Bottom nav (`HelioBottomNav`):**

| Index | Label | Screen |
|-------|-------|--------|
| 0 | Home | `HomeScreen` |
| 1 | Sleep | `SleepHubScreen` |
| 2 | Activity | `ActivityHubScreen` |
| 3 | More | `SettingsHubScreen` |

**GoRouter routes:**

| Route | Screen |
|-------|--------|
| `/` | `HelioShell` |
| `/auth` | `AuthKeyScreen` |
| `/scan` | `DeviceScanScreen` |
| `/settings/api` | `ApiSettingsScreen` |
| `/health/:dayKey` | `HealthMonitorScreen` |
| `/metric/:dayKey/:metricId` | `MetricDetailScreen` |
| `/activity/detail` | `ActivityDetailScreen` |

---

## Screen specs (implemented)

### HomeScreen
- `HelioSyncStrip` — sync state, type progress, battery
- `HelioTopBar` — date nav via `selectedDayProvider`
- `HomePrimaryRings` — Recovery, Sleep, Strain
- `HomeStatusRow` — health monitor shortcut + stress
- `HomeMyDaySection`, `HomeActivitiesSection`
- Pull-to-refresh → `liveHealthProvider.reload()`

### SleepHubScreen
- `SleepHero` + `SleepNightList`
- Tap row → `/metric/{dayKey}/sleep`

### ActivityHubScreen
- Workouts | Auto sessions tabs
- Tap → `/activity/detail`

### HealthMonitorScreen
- BPM hero + `HelioMonitorPanel.forDay()`
- Tap tile → `/metric/...`

### MetricDetailScreen
- Hero ring/value, stats, charts (`MinuteSeriesChart`, `TemperatureChart`, `SleepMetricBody`)

### SettingsHubScreen
- Sync now, retry upload, scan device, Cloud API, sync log, build marker

---

## Auto-connect & sync

1. `sync_orchestrator` init → auto pipeline when auth key + API configured
2. No MAC → `AutoStrapService.scanAndPair()`
3. `HelioShell` lifecycle resume → retry connect
4. After sync idle → `liveHealthProvider.reload()`

---

## Sleep / recovery rules

- **Recovery** = `DayMetric.readiness`
- **Sleep list:** show night if any sleep field present
- Never silent empty — use `HelioEmptyState`

---

## Verification checklist

- [x] `flutter analyze` — 0 errors, 0 warnings
- [x] Layer-first layout
- [x] Dead code removed
- [x] Single spacing + metric color tokens
- [x] Auto-connect on cold start (with saved MAC + API)
- [x] Home rings + monitor grid
- [x] Sleep tab lists nights
- [x] Settings sync/log works

---

## Logging

- `AppLogger.instance.log()` — logcat + Talker (debug)
- `AppLogger.instance.createApiDio()` — TalkerDioLogger for HTTP (debug)
- No provider or main.dart setup required
