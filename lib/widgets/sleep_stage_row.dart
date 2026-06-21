import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/utils/formatters.dart';

/// WHOOP-style single sleep stage row:
/// ○  STAGE NAME  ···  X%  duration
/// ████████████░░░░░░░ (progress bar)
class SleepStageRow extends StatelessWidget {
  final String label;
  final Color color;
  final int minutes;
  final int totalMinutes;

  const SleepStageRow({
    super.key,
    required this.label,
    required this.color,
    required this.minutes,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalMinutes > 0 ? (minutes / totalMinutes).clamp(0.0, 1.0) : 0.0;
    final pctStr = totalMinutes > 0 ? '${(pct * 100).round()}%' : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HelioSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Stage colour dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              const SizedBox(width: HelioSpacing.md),
              Text(
                label.toUpperCase(),
                style: HelioTypography.capsLabel.copyWith(fontSize: 11),
              ),
              const Spacer(),
              Text(
                pctStr,
                style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
              ),
              const SizedBox(width: HelioSpacing.sm),
              Text(
                formatSleepMins(minutes),
                style: HelioTypography.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HelioColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: HelioSpacing.xs + 2),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: HelioColors.ringTrack,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
