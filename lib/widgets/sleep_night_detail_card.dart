import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/widgets/sleep_hypnogram_chart.dart';
import 'package:heliolytics/widgets/sleep_efficiency_panel.dart';
import 'package:heliolytics/widgets/sleep_stress_card.dart';

class SleepNightDetailCard extends StatelessWidget {
  const SleepNightDetailCard({
    super.key,
    required this.bundle,
    this.stressSamples = const [],
  });

  final DayBundle bundle;
  final List<HealthSample> stressSamples;

  @override
  Widget build(BuildContext context) {
    final day = bundle.day;
    final sleep = bundle.mainSleep;
    final deep = day.sleepDeepMins ?? sleep?.deepMins ?? 0;
    final rem = day.sleepRemMins ?? sleep?.remMins ?? 0;
    final light = day.sleepLightMins ?? sleep?.lightMins ?? 0;
    final wake = sleep?.wakeMins ?? 0;
    final total =
        day.sleepMins ?? sleep?.totalMins ?? deep + rem + light + wake;
    final overnightStress = _overnightStress(sleep, stressSamples);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.lg),
          child: SleepEfficiencyPanel(
            totalMinutes: total,
            awakeMinutes: wake,
            deepMinutes: deep,
            remMinutes: rem,
            lightMinutes: light,
            stages: sleep?.stages ?? const [],
          ),
        ),
        if (overnightStress.length > 1) ...[
          const SizedBox(height: HelioSpacing.lg),
          SleepStressCard(samples: overnightStress),
        ],
        if (sleep != null && sleep.stages.isNotEmpty) ...[
          const SizedBox(height: HelioSpacing.lg),
          HelioSurfaceCard(
            padding: const EdgeInsets.all(HelioSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('SLEEP CYCLE', style: HelioTypography.sectionTitle),
                const SizedBox(height: HelioSpacing.sm),
                SleepHypnogramChart(stages: sleep.stages),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<HealthSample> _overnightStress(
    SleepMetric? sleep,
    List<HealthSample> samples,
  ) {
    if (sleep == null) return samples;
    final end = sleep.startedAt.add(
      Duration(minutes: sleep.totalMins + sleep.wakeMins),
    );
    return samples
        .where(
          (sample) =>
              !sample.sampledAt.isBefore(sleep.startedAt) &&
              !sample.sampledAt.isAfter(end),
        )
        .toList();
  }
}
