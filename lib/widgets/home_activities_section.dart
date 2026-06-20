import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/sport_icons.dart';
import 'package:heliolytics/utils/sport_labels.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/cloud_metrics_snapshot.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/activity_detail_payload.dart';
import 'package:intl/intl.dart';

class HomeActivitiesSection extends StatelessWidget {
  final CloudMetricsSnapshot snap;
  final DayMetric day;

  const HomeActivitiesSection({super.key, required this.snap, required this.day});

  @override
  Widget build(BuildContext context) {
    final sleep = snap.mainSleepFor(day.dayKey);
    final workouts = snap.workoutsFor(day.dayKey).take(2).toList();
    if (sleep == null && workouts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "TODAY'S ACTIVITIES",
                style: HelioTypography.capsLabel.copyWith(fontSize: 11),
              ),
            ),
            Icon(Icons.open_in_full, size: 16, color: HelioColors.textMuted),
          ],
        ),
        const SizedBox(height: HelioSpacing.sm),
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.md),
          child: Column(
            children: [
              if (sleep != null)
                _sleepRow(context, sleep.totalMins, sleep.startedAt),
              ...workouts.map((w) {
                final title = w.sportName.isNotEmpty
                    ? w.sportName
                    : sportLabel(w.sportType);
                return _activityRow(
                  context,
                  icon: sportIcon(w.sportType, name: title),
                  label: title,
                  duration: formatDurationSec(w.durationSec),
                  start: w.startedAt,
                  color: HelioColors.strainBlue,
                  onTap: () => context.push(
                    '/activity/detail',
                    extra: ActivityDetailPayload.workout(w),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sleepRow(BuildContext context, int mins, DateTime startedAt) {
    final end = startedAt.add(Duration(minutes: mins));
    return _activityRow(
      context,
      icon: Icons.nightlight_round,
      label: 'Sleep',
      duration: formatSleepDurationShort(mins),
      start: startedAt,
      end: end,
      color: HelioColors.sleepBlue,
      onTap: () => context.push('/metric/${day.dayKey}/sleep'),
    );
  }

  Widget _activityRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String duration,
    required DateTime start,
    DateTime? end,
    required Color color,
    VoidCallback? onTap,
  }) {
    final timeFmt = DateFormat.jm();
    final endTime = end ?? start;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HelioRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HelioSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(HelioRadii.sm),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    duration,
                    style: HelioTypography.capsLabel.copyWith(fontSize: 9, color: color),
                  ),
                ],
              ),
            ),
            const SizedBox(width: HelioSpacing.md),
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: HelioTypography.capsLabel.copyWith(
                  color: HelioColors.textPrimary,
                  fontSize: 11,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeFmt.format(start.toLocal()), style: HelioTypography.bodyMuted),
                Text(timeFmt.format(endTime.toLocal()), style: HelioTypography.bodyMuted),
              ],
            ),
            const SizedBox(width: HelioSpacing.sm),
            Container(width: 3, height: 36, color: color),
          ],
        ),
      ),
    );
  }
}
