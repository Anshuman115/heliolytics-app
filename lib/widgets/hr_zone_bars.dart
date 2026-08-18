import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/hr_zones.dart';

/// Time-in-zone breakdown: one row per zone (5 → 0), each with
/// its bpm range, % of session, duration, and a proportional bar.
class HrZoneBars extends StatelessWidget {
  final HrZoneBreakdown breakdown;

  const HrZoneBars({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final total = breakdown.totalSeconds;
    // Highest zone first, matching the screenshots.
    final ordered = breakdown.zones.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final z in ordered) ...[
          _ZoneRow(zone: z, totalSeconds: total),
          if (z != ordered.last) const SizedBox(height: HelioSpacing.md),
        ],
      ],
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final HrZone zone;
  final int totalSeconds;

  const _ZoneRow({required this.zone, required this.totalSeconds});

  @override
  Widget build(BuildContext context) {
    final frac = totalSeconds > 0 ? zone.seconds / totalSeconds : 0.0;
    final pct = (frac * 100).round();
    final color = hrZoneColor(zone.index);
    final range = zone.highBpm == null
        ? '${zone.lowBpm}+ bpm'
        : '${zone.lowBpm}–${zone.highBpm} bpm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 54,
              child: Text(
                'ZONE ${zone.index}',
                style: HelioTypography.capsLabel.copyWith(
                  fontSize: 11,
                  color: HelioColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: HelioSpacing.sm),
            Expanded(
              child: Text(
                range,
                style: HelioTypography.bodyMuted.copyWith(fontSize: 11),
              ),
            ),
            Text('$pct%',
                style: HelioTypography.bodyMuted.copyWith(fontSize: 11)),
            const SizedBox(width: HelioSpacing.sm),
            Text(
              formatDurationSec(zone.seconds),
              style: HelioTypography.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: HelioSpacing.xs + 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(HelioRadii.pill),
          child: LinearProgressIndicator(
            value: frac.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: HelioColors.surfaceElevated,
            color: color,
          ),
        ),
      ],
    );
  }
}
