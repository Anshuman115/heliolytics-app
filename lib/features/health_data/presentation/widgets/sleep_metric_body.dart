import 'package:flutter/material.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/features/health_data/domain/entities/cloud_metrics_snapshot.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/domain/metric_catalog.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/sleep_hypnogram_chart.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/sleep_stage_bar.dart';

class SleepMetricBody extends StatelessWidget {
  const SleepMetricBody({super.key, required this.snap, required this.day});

  final CloudMetricsSnapshot snap;
  final DayMetric day;

  @override
  Widget build(BuildContext context) {
    final sleep = snap.mainSleepFor(day.dayKey);
    final naps = snap.napsFor(day.dayKey);
    final deep = day.sleepDeepMins ?? sleep?.deepMins ?? 0;
    final rem = day.sleepRemMins ?? sleep?.remMins ?? 0;
    final light = day.sleepLightMins ?? sleep?.lightMins ?? 0;
    final wake = sleep?.wakeMins ?? 0;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Score ${day.sleepScore ?? sleep?.score ?? '—'}', style: theme.textTheme.titleMedium),
                Text(
                  '${formatSleepMins(day.sleepMins ?? sleep?.totalMins)}'
                  '${wake > 0 ? ' · awake ${wake}m' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                SleepStageBar(deep: deep, rem: rem, light: light),
                if (sleep != null && sleep.stages.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Hypnogram', style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  SleepHypnogramChart(stages: sleep.stages),
                ],
              ],
            ),
          ),
        ),
        if (naps.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Naps (${naps.length})', style: theme.textTheme.titleMedium),
          ...naps.map((n) => Card(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${formatWorkoutTime(n.startedAt)} · ${formatSleepMins(n.totalMins)}',
                        style: theme.textTheme.titleSmall,
                      ),
                      if (n.stages.isNotEmpty)
                        SleepHypnogramChart(stages: n.stages)
                      else
                        SleepStageBar(deep: n.deepMins, rem: n.remMins, light: n.lightMins),
                    ],
                  ),
                ),
              )),
        ],
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(MetricCatalog.byId('sleep')!.detail, style: theme.textTheme.bodySmall),
          ),
        ),
      ],
    );
  }
}
