import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/metric_colors.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/core/utils/sport_icons.dart';
import 'package:heliolytics/core/utils/sport_labels.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/presentation/screens/activity_detail_screen.dart';

class ActivitySessionTile extends StatelessWidget {
  final ActivitySessionMetric session;
  const ActivitySessionTile({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = session.sportName.isNotEmpty
        ? session.sportName
        : sportLabel(session.sportType);
    final icon = sportIcon(session.sportType, name: name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push(
            '/activity/detail',
            extra: ActivityDetailPayload.session(session),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: MetricColors.readiness.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: MetricColors.readiness),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: MetricColors.readiness.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Auto', style: theme.textTheme.labelSmall?.copyWith(color: MetricColors.readiness)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(formatWorkoutTime(session.startedAt), style: theme.textTheme.bodySmall),
                    if (session.calories != null || session.avgHr != null)
                      Text(
                        [
                          if (session.calories != null) '${session.calories} kcal',
                          if (session.avgHr != null) 'avg ${session.avgHr} bpm',
                        ].join(' · '),
                        style: theme.textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
              Text(formatDurationSec(session.durationSec), style: theme.textTheme.titleSmall),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
