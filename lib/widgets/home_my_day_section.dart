import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';

class HomeMyDaySection extends StatelessWidget {
  final DayMetric day;
  final VoidCallback? onTap;
  final VoidCallback? onAddTap;

  const HomeMyDaySection({
    super.key,
    required this.day,
    this.onTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'My Day',
              style: HelioTypography.scoreMedium.copyWith(fontSize: 18),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onAddTap ?? onTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: HelioColors.textPrimary,
                  borderRadius: BorderRadius.circular(HelioRadii.sm),
                ),
                child: const Icon(
                  Icons.add,
                  size: 20,
                  color: HelioColors.canvasBottom,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: HelioSpacing.md),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(HelioRadii.card),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF29224F), Color(0xFF193E4B)],
                ),
                borderRadius: BorderRadius.circular(HelioRadii.card),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: HelioSpacing.lg,
                vertical: HelioSpacing.md,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.nightlight_outlined,
                    color: HelioColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: HelioSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Day In Review',
                          style: HelioTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: HelioSpacing.xs),
                        Text(
                          _summary,
                          style: HelioTypography.bodyMuted.copyWith(
                            color: HelioColors.textPrimary.withValues(
                              alpha: 0.72,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: HelioColors.textPrimary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _summary {
    final sleep = day.sleepScore == null ? '--' : '${day.sleepScore}%';
    final recovery = day.readiness == null ? '--' : '${day.readiness}%';
    final strain = day.paiScore == null
        ? '--'
        : (day.paiScore! / 10).toStringAsFixed(1);
    return 'Sleep $sleep  |  Recovery $recovery  |  Strain $strain';
  }
}
