import 'package:flutter/material.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/metric_colors.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/sleep_stage_bar.dart';

class DayCard extends StatelessWidget {
  final DayMetric day;
  final SleepMetric? sleep;
  final VoidCallback onTap;

  const DayCard({super.key, required this.day, this.sleep, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deep = day.sleepDeepMins ?? sleep?.deepMins ?? 0;
    final rem = day.sleepRemMins ?? sleep?.remMins ?? 0;
    final light = day.sleepLightMins ?? sleep?.lightMins ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(formatDayLabel(day.dayKey), style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      formatSteps(day.steps).replaceAll(' steps', ''),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(' steps', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 6,
                  children: [
                    if (day.paiScore != null) _pill('PAI', '${day.paiScore}', MetricColors.pai),
                    if (day.restingHr != null) _pill('RHR', '${day.restingHr}', MetricColors.restingHr),
                    if (day.stressAvg != null) _pill('Stress', '${day.stressAvg}', MetricColors.stress),
                    if (day.hrvRmssd != null) _pill('HRV', '${day.hrvRmssd}', MetricColors.hrv),
                    if (day.spo2Avg != null) _pill('SpO₂', '${day.spo2Avg}%', MetricColors.spo2),
                    if (day.workoutCount > 0) _pill('Sports', '${day.workoutCount}', MetricColors.readiness),
                  ],
                ),
                if (day.sleepMins != null || sleep != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Sleep ${day.sleepScore ?? sleep?.score ?? '—'} · ${formatSleepMins(day.sleepMins ?? sleep?.totalMins)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SleepStageBar(deep: deep, rem: rem, light: light),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String l, String v, Color c) {
    return Semantics(
      label: '$l $v',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.35)),
        ),
        child: Text('$l $v', style: TextStyle(fontSize: 12, color: c)),
      ),
    );
  }
}
