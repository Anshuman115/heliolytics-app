import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/utils/stress_zones.dart';
import 'package:heliolytics/widgets/stress/stress_zone_color.dart';

const _zones = [StressZone.low, StressZone.medium, StressZone.high];

String _hhmm(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

/// Proportional bar + per-zone durations for one stress split.
class StressZoneSplit extends StatelessWidget {
  final StressSplit split;

  const StressZoneSplit({super.key, required this.split});

  @override
  Widget build(BuildContext context) {
    if (!split.hasData) {
      return Text(
        'No stress readings for this period.',
        style: HelioTypography.bodyMuted,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _bar(),
        const SizedBox(height: HelioSpacing.md),
        Row(
          children: [
            for (final z in _zones)
              Expanded(child: _legend(z)),
          ],
        ),
      ],
    );
  }

  Widget _bar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final z in _zones)
              if (split.minutesIn(z) > 0)
                Expanded(
                  flex: split.minutesIn(z),
                  child: ColoredBox(color: stressZoneColor(z)),
                ),
          ],
        ),
      ),
    );
  }

  Widget _legend(StressZone z) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _hhmm(split.minutesIn(z)),
          style: HelioTypography.scoreMedium.copyWith(fontSize: 20),
        ),
        const SizedBox(height: HelioSpacing.xs),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: stressZoneColor(z),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              stressZoneLabel(z),
              style: HelioTypography.capsLabel.copyWith(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}
