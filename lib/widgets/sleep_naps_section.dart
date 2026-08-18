import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/widgets/sleep_hypnogram_chart.dart';

class SleepNapsSection extends StatelessWidget {
  const SleepNapsSection({super.key, required this.naps});

  final List<SleepMetric> naps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('NAPS (${naps.length})', style: HelioTypography.sectionTitle),
        const SizedBox(height: HelioSpacing.sm),
        ...naps.map(
          (nap) => Padding(
            padding: const EdgeInsets.only(bottom: HelioSpacing.sm),
            child: HelioSurfaceCard(
              padding: const EdgeInsets.all(HelioSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        formatWorkoutTime(nap.startedAt),
                        style: HelioTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatSleepMins(nap.totalMins),
                        style: HelioTypography.bodyMuted,
                      ),
                    ],
                  ),
                  if (nap.stages.isNotEmpty) ...[
                    const SizedBox(height: HelioSpacing.md),
                    SleepHypnogramChart(stages: nap.stages),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
