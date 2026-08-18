import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';

class HomeDailyInsight extends StatelessWidget {
  const HomeDailyInsight({super.key, required this.day, required this.onTap});

  final DayMetric day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final insight = _insight();
    return HelioSurfaceCard(
      onTap: onTap,
      color: HelioColors.surface,
      padding: const EdgeInsets.all(HelioSpacing.lg),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.$3,
                  style: HelioTypography.scoreMedium.copyWith(fontSize: 20),
                ),
                const SizedBox(height: HelioSpacing.xs),
                Text(
                  insight.$4,
                  style: HelioTypography.bodyMuted.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 34,
              height: 52,
              decoration: BoxDecoration(
                color: HelioColors.surfaceElevated,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.check, color: insight.$2, size: 23),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String, String) _insight() {
    final recovery = day.readiness;
    final hrv = day.hrvRmssd;
    if (recovery != null && recovery >= 67 && hrv != null) {
      return (
        Icons.favorite_outline,
        HelioColors.recoveryHigh,
        'Strong overnight baseline',
        'Recovery is $recovery% with an overnight HRV of $hrv ms. Use that capacity well and check strain as the day builds.',
      );
    }
    if (recovery != null && recovery >= 67) {
      return (
        Icons.bolt_outlined,
        HelioColors.recoveryHigh,
        'Ready for a stronger day',
        'Recovery is high. Use your current energy well, then check strain as the day builds.',
      );
    }
    if (recovery != null && recovery <= 33) {
      return (
        Icons.self_improvement_outlined,
        HelioColors.recoveryLow,
        'Prioritize recovery today',
        'Your overnight recovery is low. Keep training easy and make sleep the main focus tonight.',
      );
    }
    if (day.sleepMins != null && day.sleepMins! < 420) {
      return (
        Icons.bedtime_outlined,
        HelioColors.sleepBlue,
        'Sleep was shorter than target',
        'You logged less than seven hours. Keep the next hard session flexible and protect your bedtime.',
      );
    }
    return (
      Icons.insights_outlined,
      HelioColors.strainBlue,
      'Build your day deliberately',
      'Use recovery, sleep, and strain together instead of relying on one score alone.',
    );
  }
}
