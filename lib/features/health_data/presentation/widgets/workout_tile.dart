import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/metric_colors.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/core/utils/sport_icons.dart';
import 'package:heliolytics/core/utils/sport_labels.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/presentation/screens/activity_detail_screen.dart';

class WorkoutTile extends StatelessWidget {
  final WorkoutMetric workout;
  final String? dayKey;
  const WorkoutTile({super.key, required this.workout, this.dayKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = workout.sportName.isNotEmpty
        ? workout.sportName
        : sportLabel(workout.sportType);
    final icon = sportIcon(workout.sportType, name: name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push(
            '/activity/detail',
            extra: ActivityDetailPayload.workout(workout),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: MetricColors.workout.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: MetricColors.workout),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(formatWorkoutTime(workout.startedAt), style: theme.textTheme.bodySmall),
                      if (workout.calories != null || workout.avgHr != null)
                        Text(
                          [
                            if (workout.calories != null) '${workout.calories} kcal',
                            if (workout.avgHr != null) 'avg ${workout.avgHr} bpm',
                            if (workout.maxHr != null) 'max ${workout.maxHr}',
                          ].join(' · '),
                          style: theme.textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
                Text(
                  formatDurationSec(workout.durationSec),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
