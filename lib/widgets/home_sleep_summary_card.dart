import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/utils/formatters.dart';

class HomeSleepSummaryCard extends StatelessWidget {
  const HomeSleepSummaryCard({
    super.key,
    required this.sleep,
    required this.onTap,
  });

  final SleepMetric sleep;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => HelioSurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.all(HelioSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text("LAST NIGHT'S SLEEP", style: HelioTypography.sectionTitle),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: HelioColors.textMuted,
              size: 22,
            ),
          ],
        ),
        const SizedBox(height: HelioSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${sleep.score}%',
              style: HelioTypography.scoreLarge.copyWith(
                color: HelioColors.sleepBlue,
                fontSize: 34,
              ),
            ),
            const SizedBox(width: HelioSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('performance', style: HelioTypography.bodyMuted),
            ),
            const Spacer(),
            Text(
              formatSleepDurationShort(sleep.totalMins),
              style: HelioTypography.scoreMedium.copyWith(fontSize: 28),
            ),
            const SizedBox(width: HelioSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('asleep', style: HelioTypography.bodyMuted),
            ),
          ],
        ),
        const SizedBox(height: HelioSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(HelioRadii.sm),
          child: Row(
            children: [
              _stage(sleep.lightMins, HelioColors.sleepLight),
              _stage(sleep.remMins, HelioColors.sleepRem),
              _stage(sleep.deepMins, HelioColors.sleepDeep),
              _stage(sleep.wakeMins, HelioColors.sleepAwake),
            ],
          ),
        ),
        const SizedBox(height: HelioSpacing.sm),
        Row(
          children: [
            _label('LIGHT', sleep.lightMins),
            _label('REM', sleep.remMins),
            _label('DEEP', sleep.deepMins),
            _label('AWAKE', sleep.wakeMins),
          ],
        ),
      ],
    ),
  );

  Widget _stage(int minutes, Color color) => Expanded(
    flex: minutes.clamp(1, 1440),
    child: Container(height: 8, color: color),
  );

  Widget _label(String label, int minutes) => Expanded(
    child: Text(
      '$label ${minutes}m',
      style: HelioTypography.capsLabel.copyWith(fontSize: 9),
      overflow: TextOverflow.ellipsis,
    ),
  );
}
