import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/features/health_data/domain/entities/cloud_metrics_snapshot.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/domain/metric_catalog.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/metric_stats_row.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/minute_series_chart.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/rollup_metric_card.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/sleep_metric_body.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/temperature_chart.dart';

class MetricDetailScreen extends ConsumerWidget {
  final String dayKey;
  final String metricId;

  const MetricDetailScreen({super.key, required this.dayKey, required this.metricId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = MetricCatalog.byId(metricId);
    if (def == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Unknown metric')));
    }
    final snap = ref.watch(liveHealthProvider).valueOrNull;
    DayMetric? day;
    for (final d in snap?.days ?? const <DayMetric>[]) {
      if (d.dayKey == dayKey) {
        day = d;
        break;
      }
    }
    if (snap == null || day == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('${def.title} · ${formatDayLabel(dayKey)}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _header(context, def, day),
          const SizedBox(height: AppSpacing.md),
          ..._body(context, def, snap, day),
        ],
      ),
    );
  }

  Widget _header(BuildContext ctx, MetricDef def, DayMetric day) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: def.color.withValues(alpha: 0.15),
          child: Icon(def.icon, color: def.color, size: 28),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(def.summaryValue(day), style: Theme.of(ctx).textTheme.headlineSmall),
              Text(def.note, style: Theme.of(ctx).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _body(BuildContext ctx, MetricDef def, CloudMetricsSnapshot snap, DayMetric day) {
    if (def.id == 'sleep') return _sleepBody(ctx, snap, day);
    if (def.id == 'temperature') return _tempBody(ctx, snap);
    if (def.seriesKey == null) {
      return [
        RollupMetricCard(def: def, valueLabel: def.summaryValue(day), onTap: null),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(def.detail, style: Theme.of(ctx).textTheme.bodyMedium),
          ),
        ),
      ];
    }
    final samples = snap.series.where((s) => s.dayKey == dayKey && s.metric == def.seriesKey).toList();
    final stats = MetricStats.fromSamples(samples);
    return [
      MetricStatsRow(stats: stats, unit: def.unit),
      const SizedBox(height: AppSpacing.md),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: MinuteSeriesChart(
            samples: samples,
            color: def.color,
            unit: def.unit,
            height: 280,
            maxPoints: 480,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(def.detail, style: Theme.of(ctx).textTheme.bodySmall),
        ),
      ),
    ];
  }

  List<Widget> _sleepBody(BuildContext ctx, CloudMetricsSnapshot snap, DayMetric day) {
    return [SleepMetricBody(snap: snap, day: day)];
  }

  List<Widget> _tempBody(BuildContext ctx, CloudMetricsSnapshot snap) {
    final temps = snap.tempFor(dayKey);
    final stats = MetricStats.fromTemp(temps);
    return [
      MetricStatsRow(stats: stats, unit: '°C'),
      const SizedBox(height: AppSpacing.md),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: TemperatureChart(samples: temps, height: 280),
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(MetricCatalog.byId('temperature')!.detail, style: Theme.of(ctx).textTheme.bodySmall),
        ),
      ),
    ];
  }
}
