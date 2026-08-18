import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/utils/stress_zones.dart';
import 'package:heliolytics/widgets/stress/stress_zone_split.dart';

class StressSleepSummaryCard extends StatelessWidget {
  const StressSleepSummaryCard({super.key, required this.samples});

  final List<HealthSample> samples;

  @override
  Widget build(BuildContext context) {
    final split = splitStressByZone(samples);
    return HelioSurfaceCard(
      padding: const EdgeInsets.fromLTRB(
        HelioSpacing.lg,
        HelioSpacing.lg,
        HelioSpacing.lg,
        HelioSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StressZoneSplit(split: split),
          const SizedBox(height: HelioSpacing.lg),
          Text(
            'Stress experienced during sleep.',
            style: HelioTypography.body.copyWith(
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          if (split.hasData) ...[
            const SizedBox(height: HelioSpacing.lg),
            Row(
              children: [
                Text('SEE TRENDS', style: HelioTypography.sectionTitle),
                const SizedBox(width: HelioSpacing.sm),
                const Icon(Icons.arrow_forward, size: 25),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
