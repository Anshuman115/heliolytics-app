import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/utils/formatters.dart';

class ActivityLoadPanel extends StatelessWidget {
  const ActivityLoadPanel({
    super.key,
    required this.day,
    required this.workoutCount,
    required this.autoCount,
  });

  final DayMetric day;
  final int workoutCount;
  final int autoCount;

  @override
  Widget build(BuildContext context) {
    return HelioSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: HelioSpacing.sm),
      child: Column(
        children: [
          _row(
            icon: Icons.directions_walk_outlined,
            label: 'STEPS',
            value: day.steps > 0 ? formatStepCount(day.steps) : 'No data',
            color: HelioColors.strainBlue,
          ),
          _divider(),
          _row(
            icon: Icons.fitness_center_outlined,
            label: 'RECORDED ACTIVITIES',
            value: workoutCount == 0
                ? 'None'
                : '$workoutCount ${workoutCount == 1 ? 'activity' : 'activities'}',
            color: HelioColors.textPrimary,
          ),
          _divider(),
          _row(
            icon: Icons.auto_graph,
            label: 'AUTO-DETECTED',
            value: autoCount == 0
                ? 'None'
                : '$autoCount ${autoCount == 1 ? 'session' : 'sessions'}',
            color: HelioColors.textSecondary,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool last = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HelioSpacing.lg,
        vertical: HelioSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: HelioSpacing.md),
          Expanded(child: Text(label, style: HelioTypography.capsLabel)),
          Text(
            value,
            style: HelioTypography.body.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
    height: 1,
    thickness: 1,
    color: HelioColors.border,
  );
}
