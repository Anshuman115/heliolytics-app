import 'package:flutter/material.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/design_system/components/helio_score_ring.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/widgets/sleep_performance_bars.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/widgets/sleep_stage_bar.dart';

class SleepHero extends StatelessWidget {
  final DayBundle bundle;
  final String dayKey;

  const SleepHero({super.key, required this.bundle, required this.dayKey});

  @override
  Widget build(BuildContext context) {
    final day = bundle.day;
    final sleep = bundle.mainSleep;
    final score = day.sleepScore ?? sleep?.score;
    final mins = day.sleepMins ?? sleep?.totalMins;
    final deep = day.sleepDeepMins ?? sleep?.deepMins ?? 0;
    final rem = day.sleepRemMins ?? sleep?.remMins ?? 0;
    final light = day.sleepLightMins ?? sleep?.lightMins ?? 0;
    final progress = score != null ? score / 100.0 : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(formatNavDayLabel(dayKey), style: HelioTypography.sectionTitle),
        const SizedBox(height: HelioSpacing.lg),
        Center(
          child: HelioScoreRing(
            size: HelioRingSize.hero,
            progress: progress,
            label: 'Sleep Performance',
            value: score != null ? '$score%' : '—',
            color: HelioColors.sleepRem,
          ),
        ),
        const SizedBox(height: HelioSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pill('Slept', formatSleepMins(mins)),
            const SizedBox(width: HelioSpacing.sm),
            _pill('Needed', '8h 0m'),
          ],
        ),
        if (deep + rem + light > 0) ...[
          const SizedBox(height: HelioSpacing.lg),
          SleepStageBar(deep: deep, rem: rem, light: light),
        ],
        const SizedBox(height: HelioSpacing.lg),
        SleepPerformanceBars(sleepMins: mins, sleepScore: score),
      ],
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HelioSpacing.lg,
        vertical: HelioSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: HelioColors.surface,
        borderRadius: BorderRadius.circular(HelioRadii.pill),
        border: Border.all(color: HelioColors.border),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: HelioTypography.capsLabel),
          const SizedBox(height: 2),
          Text(value, style: HelioTypography.body),
        ],
      ),
    );
  }
}
