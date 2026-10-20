import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_score_ring.dart';
import 'package:heliolytics/design_system/components/helio_notched_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/sleep_stage.dart';
import 'package:heliolytics/widgets/sleep_performance_bars.dart';
import 'package:heliolytics/models/day_bundle.dart';

class SleepHero extends StatelessWidget {
  final DayBundle bundle;
  final List<HealthSample> stressSamples;

  const SleepHero({
    super.key,
    required this.bundle,
    this.stressSamples = const [],
  });

  @override
  Widget build(BuildContext context) {
    final day = bundle.day;
    final sleep = bundle.mainSleep;
    final score = day?.sleepScore ?? sleep?.score;
    final mins = day?.sleepMins ?? sleep?.totalMins;
    final progress = score != null ? score / 100.0 : null;
    final highSleepStress = _highSleepStress(sleep);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: HelioScoreRing(
            size: HelioRingSize.heroXl,
            progress: progress,
            label: 'Sleep\nPerformance',
            value: score != null ? '$score%' : '—',
            color: HelioColors.sleepBlue,
            eyebrow: 'HELIOLYTICS',
            showScoreBars: true,
          ),
        ),
        const SizedBox(height: HelioSpacing.xl),
        HelioNotchedCard(
          padding: const EdgeInsets.all(HelioSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SleepPerformanceBars(
                sleepMins: mins,
                sleepEfficiency: day?.sleepEfficiencyPct,
                highSleepStress: highSleepStress,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Share of overnight stress samples at or above 80, from real 0x13 points.
  int? _highSleepStress(SleepSession? sleep) {
    if (sleep == null || stressSamples.isEmpty) return null;
    final overnight = stressSamples
        .where(
          (sample) =>
              !sample.sampledAt.isBefore(sleep.startedAt) &&
              sample.sampledAt.isBefore(sleep.endedAt),
        )
        .toList();
    if (overnight.isEmpty) return null;
    final high = overnight.where((sample) => sample.value >= 80).length;
    return (high * 100 / overnight.length).round();
  }
}
