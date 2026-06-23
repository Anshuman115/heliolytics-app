import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/metric_progress.dart';
import 'package:heliolytics/design_system/components/helio_empty_state.dart';
import 'package:heliolytics/design_system/components/helio_insight_card.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_score_ring.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/cloud_metrics_snapshot.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/widgets/metric_stats_row.dart';
import 'package:heliolytics/widgets/minute_series_chart.dart';
import 'package:heliolytics/widgets/sleep_metric_body.dart';
import 'package:heliolytics/widgets/temperature_chart.dart';
import 'package:heliolytics/utils/hr_chart_samples.dart';
import 'package:heliolytics/design_system/tokens/helio_metric_colors.dart';

class MetricDetailScreen extends ConsumerWidget {
  final String dayKey;
  final String metricId;

  const MetricDetailScreen({super.key, required this.dayKey, required this.metricId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = MetricCatalog.byId(metricId);
    if (def == null) {
      return Scaffold(
        appBar: HelioTopBar(showBack: true, onBack: () => context.pop()),
        body: const Center(child: Text('Unknown metric')),
      );
    }

    final health = ref.watch(liveHealthProvider);
    final detail = ref.watch(detailMetricsProvider).valueOrNull ?? const DetailMetrics();
    return health.when(
      loading: () => Scaffold(
        appBar: HelioTopBar(showBack: true, onBack: () => context.pop()),
        body: const HelioLoading(),
      ),
      error: (e, _) => Scaffold(
        appBar: HelioTopBar(showBack: true, onBack: () => context.pop()),
        body: HelioEmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load',
          message: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(liveHealthProvider),
        ),
      ),
      data: (snap) => _loaded(context, def, snap, detail),
    );
  }

  Widget _loaded(BuildContext context, MetricDef def, CloudMetricsSnapshot? snap,
      DetailMetrics detail) {
    DayMetric? day;
    for (final d in snap?.days ?? const <DayMetric>[]) {
      if (d.dayKey == dayKey) {
        day = d;
        break;
      }
    }

    if (snap == null || day == null) {
      return Scaffold(
        appBar: HelioTopBar(showBack: true, onBack: () => context.pop()),
        body: const HelioEmptyState(
          icon: Icons.calendar_today_outlined,
          title: 'Day not found',
          message: 'No metrics for this date. Try syncing your strap.',
        ),
      );
    }

    return Scaffold(
      appBar: HelioTopBar(
        showBack: true,
        onBack: () => context.pop(),
        dayLabel: '${def.title} · ${formatDayLabel(dayKey)}',
      ),
      body: ListView(
        padding: const EdgeInsets.all(HelioSpacing.lg),
        children: [
          if (def.id != 'continuous_hr') _hero(def, day),
          if (def.id == 'readiness' && day.readiness == null) ...[
            const SizedBox(height: HelioSpacing.lg),
            HelioInsightCard(
              message: _readinessHint(snap),
              icon: Icons.info_outline,
            ),
          ],
          const SizedBox(height: HelioSpacing.lg),
          ..._body(def, snap, day, detail),
        ],
      ),
    );
  }

  String _readinessHint(CloudMetricsSnapshot snap) {
    return 'Your recovery score is calculated from overnight HRV, resting heart '
        'rate, sleep, and breathing rate compared to your personal baseline. It '
        'needs about 7 nights of data to calibrate — keep wearing the strap '
        'overnight and it will appear.';
  }

  Widget _hero(MetricDef def, DayMetric day) {
    final value = def.summaryValue(day);
    final progress = _progressFor(def.id, day);
    final color = def.id == 'readiness' ? recoveryColorFor(day.readiness) : def.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HelioSpacing.xl),
      child: Center(
        child: HelioScoreRing(
          size: HelioRingSize.whoopHero,
          progress: progress,
          label: def.title,
          value: value,
          color: color,
          showChevron: false,
        ),
      ),
    );
  }

  double? _progressFor(String id, DayMetric day) {
    return switch (id) {
      'readiness' => metricProgress(MetricKind.readiness, day.readiness),
      'sleep' => metricProgress(MetricKind.sleep, day.sleepScore),
      'stress' => metricProgress(MetricKind.stress, day.stressAvg),
      'hrv' => metricProgress(MetricKind.hrv, day.hrvRmssd),
      'rhr' => metricProgress(MetricKind.restingHr, day.restingHr),
      'pai' => metricProgress(MetricKind.pai, day.paiScore),
      _ => null,
    };
  }

  List<Widget> _body(MetricDef def, CloudMetricsSnapshot snap, DayMetric day,
      DetailMetrics detail) {
    if (def.id == 'sleep') {
      return [HelioSurfaceCard(child: SleepMetricBody(snap: snap, day: day))];
    }
    if (def.id == 'continuous_hr') return _continuousHrBody(detail, day);
    if (def.id == 'temperature') return _tempBody(detail);
    if (def.seriesKey == null) {
      return [
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.lg),
          child: Text(def.detail, style: HelioTypography.bodyMuted),
        ),
      ];
    }
    final samples = detail.seriesFor(dayKey, def.seriesKey!);
    final stats = MetricStats.fromSamples(samples);
    return [
      MetricStatsRow(stats: stats, unit: def.unit),
      const SizedBox(height: HelioSpacing.md),
      HelioSurfaceCard(
        padding: const EdgeInsets.all(HelioSpacing.sm),
        child: MinuteSeriesChart(
          samples: samples,
          color: def.color,
          unit: def.unit,
          height: 280,
          maxPoints: 480,
        ),
      ),
      const SizedBox(height: HelioSpacing.md),
      HelioSurfaceCard(
        padding: const EdgeInsets.all(HelioSpacing.lg),
        child: Text(def.detail, style: HelioTypography.bodyMuted),
      ),
    ];
  }

  List<Widget> _continuousHrBody(DetailMetrics detail, DayMetric day) {
    final hr = detail.heartRateFor(dayKey);
    final stats = MetricStats.fromHeartRate(hr);
    final latest = hr.isEmpty ? null : hr.last;
    final heroValue = latest != null ? '${latest.bpm}' : (day.restingHr?.toString() ?? '—');
    return [
      Center(
        child: Text(
          heroValue,
          style: HelioTypography.scoreMedium.copyWith(fontSize: 48, color: HelioMetricColors.restingHr),
        ),
      ),
      if (latest != null)
        Center(
          child: Text(
            'Latest at ${formatChartTime(latest.sampledAt)}',
            style: HelioTypography.bodyMuted,
          ),
        ),
      const SizedBox(height: HelioSpacing.lg),
      MetricStatsRow(stats: stats, unit: 'bpm'),
      const SizedBox(height: HelioSpacing.md),
      HelioSurfaceCard(
        padding: const EdgeInsets.all(HelioSpacing.sm),
        child: hr.isEmpty
            ? Text(MetricCatalog.byId('continuous_hr')!.detail, style: HelioTypography.bodyMuted)
            : MinuteSeriesChart(
                samples: heartRateAsChartSamples(hr),
                color: HelioMetricColors.restingHr,
                unit: 'bpm',
                height: 280,
                maxPoints: 1200,
                showDots: false,
              ),
      ),
      const SizedBox(height: HelioSpacing.md),
      HelioSurfaceCard(
        padding: const EdgeInsets.all(HelioSpacing.lg),
        child: Text(MetricCatalog.byId('continuous_hr')!.detail, style: HelioTypography.bodyMuted),
      ),
    ];
  }

  List<Widget> _tempBody(DetailMetrics detail) {
    final temps = detail.tempFor(dayKey);
    final stats = MetricStats.fromTemp(temps);
    return [
      MetricStatsRow(stats: stats, unit: '°C'),
      const SizedBox(height: HelioSpacing.md),
      HelioSurfaceCard(
        padding: const EdgeInsets.all(HelioSpacing.sm),
        child: TemperatureChart(samples: temps, height: 280),
      ),
      HelioSurfaceCard(
        padding: const EdgeInsets.all(HelioSpacing.lg),
        child: Text(MetricCatalog.byId('temperature')!.detail, style: HelioTypography.bodyMuted),
      ),
    ];
  }
}
