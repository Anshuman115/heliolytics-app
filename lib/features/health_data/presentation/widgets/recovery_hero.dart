import 'package:flutter/material.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/metric_colors.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/core/utils/metric_progress.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';

class RecoveryHero extends StatelessWidget {
  final DayMetric day;
  final VoidCallback? onTap;

  const RecoveryHero({super.key, required this.day, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readiness = day.readiness?.toString() ?? '—';
    final progress = safeProgress(metricProgress(MetricKind.readiness, day.readiness));

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;
              final ring = compact ? 88.0 : 120.0;
              return Row(
                children: [
                  SizedBox(
                    width: ring,
                    height: ring,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: compact ? 8 : 10,
                          backgroundColor: MetricColors.readiness.withValues(alpha: 0.15),
                          color: MetricColors.readiness,
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(readiness, style: theme.textTheme.headlineSmall),
                              Text('Readiness', style: theme.textTheme.labelSmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: compact ? AppSpacing.md : AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recovery score', style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(formatSteps(day.steps), style: theme.textTheme.bodyMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          day.readiness == null
                              ? 'Re-sync after updating the API to load readiness'
                              : 'Tap for readiness details',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
