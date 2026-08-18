import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/widgets/stress/stress_day_chart.dart';

class SleepStressCard extends StatelessWidget {
  const SleepStressCard({super.key, required this.samples});

  final List<HealthSample> samples;

  @override
  Widget build(BuildContext context) {
    final high = samples.where((sample) => sample.value >= 80).length;
    final percentage = samples.isEmpty
        ? 0
        : (high * 100 / samples.length).round();
    return HelioSurfaceCard(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('SLEEP STRESS', style: HelioTypography.sectionTitle),
              const Spacer(),
              const Icon(
                Icons.info_outline,
                size: 22,
                color: HelioColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: HelioSpacing.md),
          Text(
            '$percentage%',
            style: HelioTypography.scoreLarge.copyWith(fontSize: 40),
          ),
          const SizedBox(height: HelioSpacing.md),
          StressDayChart(samples: samples),
        ],
      ),
    );
  }
}
