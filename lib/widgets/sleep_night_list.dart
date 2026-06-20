import 'package:flutter/material.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/design_system/components/helio_section_header.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/cloud_metrics_snapshot.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/widgets/sleep_stage_bar.dart';
import 'package:intl/intl.dart';

class SleepNightList extends StatelessWidget {
  final CloudMetricsSnapshot snap;
  final List<String> dayKeys;
  final void Function(String dayKey) onTap;

  const SleepNightList({
    super.key,
    required this.snap,
    required this.dayKeys,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HelioSectionHeader(title: 'All nights'),
        ...dayKeys.map((key) => _nightRow(key)),
      ],
    );
  }

  Widget _nightRow(String dayKey) {
    DayMetric? day;
    for (final d in snap.days) {
      if (d.dayKey == dayKey) {
        day = d;
        break;
      }
    }
    final sleep = snap.mainSleepFor(dayKey);
    final deep = day?.sleepDeepMins ?? sleep?.deepMins ?? 0;
    final rem = day?.sleepRemMins ?? sleep?.remMins ?? 0;
    final light = day?.sleepLightMins ?? sleep?.lightMins ?? 0;
    final score = day?.sleepScore ?? sleep?.score;
    final mins = day?.sleepMins ?? sleep?.totalMins;
    final parts = dayKey.split('-');
    final date = parts.length == 3
        ? DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]))
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: HelioSpacing.sm),
      child: HelioSurfaceCard(
        onTap: () => onTap(dayKey),
        padding: const EdgeInsets.all(HelioSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dateBlock(date, dayKey),
            const SizedBox(width: HelioSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    formatNavDayLabel(dayKey),
                    style: HelioTypography.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(formatSleepMins(mins), style: HelioTypography.bodyMuted),
                  if (deep + rem + light > 0) ...[
                    const SizedBox(height: HelioSpacing.sm),
                    SleepStageBar(deep: deep, rem: rem, light: light),
                  ],
                ],
              ),
            ),
            const SizedBox(width: HelioSpacing.sm),
            _scoreBadge(score),
          ],
        ),
      ),
    );
  }

  Widget _dateBlock(DateTime? date, String dayKey) {
    if (date == null) {
      return const SizedBox(width: 44);
    }
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: HelioSpacing.sm),
      decoration: BoxDecoration(
        color: HelioColors.surfaceElevated,
        borderRadius: BorderRadius.circular(HelioRadii.sm),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('EEE').format(date).toUpperCase(),
            style: HelioTypography.capsLabel.copyWith(fontSize: 9),
          ),
          const SizedBox(height: 2),
          Text(
            '${date.day}',
            style: HelioTypography.scoreMedium.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _scoreBadge(int? score) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: HelioColors.sleepBlue, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        score?.toString() ?? '—',
        style: HelioTypography.body.copyWith(
          fontWeight: FontWeight.w700,
          color: HelioColors.sleepBlue,
        ),
      ),
    );
  }
}
