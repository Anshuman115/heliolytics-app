import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/sleep_stage.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/widgets/sleep_timeline_bar.dart';
import 'package:heliolytics/widgets/sleep_stage_row.dart';

class SleepEfficiencyPanel extends StatelessWidget {
  const SleepEfficiencyPanel({
    super.key,
    required this.totalMinutes,
    required this.awakeMinutes,
    required this.deepMinutes,
    required this.remMinutes,
    required this.lightMinutes,
    required this.stages,
  });

  final int totalMinutes;
  final int awakeMinutes;
  final int deepMinutes;
  final int remMinutes;
  final int lightMinutes;
  final List<SleepStagePoint> stages;

  @override
  Widget build(BuildContext context) {
    final inBed = totalMinutes + awakeMinutes;
    final efficiency = inBed == 0 ? null : (totalMinutes * 100 / inBed).round();
    final wakeEvents = stages
        .where((stage) => stage.kind == SleepStageKind.awake)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('SLEEP EFFICIENCY', style: HelioTypography.sectionTitle),
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
          efficiency == null ? 'N/A' : '$efficiency%',
          style: HelioTypography.scoreLarge.copyWith(fontSize: 40),
        ),
        const SizedBox(height: HelioSpacing.lg),
        _TimelineHeading('ASLEEP', formatSleepMins(totalMinutes)),
        SleepTimelineBar(stages: stages, totalMinutes: inBed, awakeOnly: false),
        const SizedBox(height: HelioSpacing.md),
        _TimelineHeading('AWAKE', formatSleepMins(awakeMinutes)),
        SleepTimelineBar(stages: stages, totalMinutes: inBed, awakeOnly: true),
        const Divider(height: HelioSpacing.xxl, color: HelioColors.border),
        Row(
          children: [
            const Icon(
              Icons.crop_square,
              size: 20,
              color: HelioColors.textPrimary,
            ),
            const SizedBox(width: HelioSpacing.md),
            Text('WAKE EVENTS', style: HelioTypography.sectionTitle),
            const Spacer(),
            Text('$wakeEvents', style: HelioTypography.scoreMedium),
          ],
        ),
        const Divider(height: HelioSpacing.xxl, color: HelioColors.border),
        Text('SLEEP STAGES', style: HelioTypography.sectionTitle),
        const SizedBox(height: HelioSpacing.sm),
        SleepStageRow(
          label: 'Light',
          color: HelioColors.sleepLight,
          minutes: lightMinutes,
          totalMinutes: totalMinutes,
        ),
        SleepStageRow(
          label: 'REM',
          color: HelioColors.sleepRem,
          minutes: remMinutes,
          totalMinutes: totalMinutes,
        ),
        SleepStageRow(
          label: 'Deep',
          color: HelioColors.sleepDeep,
          minutes: deepMinutes,
          totalMinutes: totalMinutes,
        ),
      ],
    );
  }
}

class _TimelineHeading extends StatelessWidget {
  const _TimelineHeading(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: HelioTypography.sectionTitle),
      const Spacer(),
      Text(value, style: HelioTypography.scoreMedium.copyWith(fontSize: 18)),
    ],
  );
}
