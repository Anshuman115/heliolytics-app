import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/cloud_metrics_snapshot.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/widgets/sleep_hypnogram_chart.dart';
import 'package:heliolytics/widgets/sleep_stage_row.dart';

class SleepMetricBody extends StatelessWidget {
  const SleepMetricBody({super.key, required this.snap, required this.day});

  final CloudMetricsSnapshot snap;
  final DayMetric day;

  @override
  Widget build(BuildContext context) {
    final sleep = snap.mainSleepFor(day.dayKey);
    final naps = snap.napsFor(day.dayKey);

    final deep = day.sleepDeepMins ?? sleep?.deepMins ?? 0;
    final rem = day.sleepRemMins ?? sleep?.remMins ?? 0;
    final light = day.sleepLightMins ?? sleep?.lightMins ?? 0;
    final wake = sleep?.wakeMins ?? 0;
    final total = day.sleepMins ?? sleep?.totalMins ?? (deep + rem + light + wake);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Main sleep card ─────────────────────────────────
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row: score badge + duration
              Row(
                children: [
                  if (day.sleepScore != null || sleep?.score != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: HelioSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: HelioColors.sleepBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${day.sleepScore ?? sleep!.score}%',
                        style: HelioTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: HelioColors.sleepBlue,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: HelioSpacing.sm),
                  ],
                  Text(
                    'SLEEP SCORE',
                    style: HelioTypography.capsLabel.copyWith(fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    formatSleepMins(total > 0 ? total : null),
                    style: HelioTypography.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (wake > 0) ...[
                const SizedBox(height: HelioSpacing.xs),
                Text(
                  'Awake ${wake}m',
                  style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
                ),
              ],

              // ── Stage breakdown ──────────────────────────
              if (total > 0) ...[
                const SizedBox(height: HelioSpacing.lg),
                Text('SLEEP STAGES', style: HelioTypography.sectionTitle),
                const SizedBox(height: HelioSpacing.sm),
                if (wake > 0)
                  SleepStageRow(
                    label: 'Awake',
                    color: HelioColors.sleepAwake,
                    minutes: wake,
                    totalMinutes: total,
                  ),
                if (light > 0)
                  SleepStageRow(
                    label: 'Light',
                    color: HelioColors.sleepLight,
                    minutes: light,
                    totalMinutes: total,
                  ),
                if (deep > 0)
                  SleepStageRow(
                    label: 'Deep (SWS)',
                    color: HelioColors.sleepDeep,
                    minutes: deep,
                    totalMinutes: total,
                  ),
                if (rem > 0)
                  SleepStageRow(
                    label: 'REM',
                    color: HelioColors.sleepRem,
                    minutes: rem,
                    totalMinutes: total,
                  ),
              ],

              // ── Hypnogram ────────────────────────────────
              if (sleep != null && sleep.stages.isNotEmpty) ...[
                const SizedBox(height: HelioSpacing.lg),
                const Divider(height: 1, color: Color(0x14FFFFFF)),
                const SizedBox(height: HelioSpacing.lg),
                Text('HYPNOGRAM', style: HelioTypography.sectionTitle),
                const SizedBox(height: HelioSpacing.sm),
                SleepHypnogramChart(stages: sleep.stages),
              ],
            ],
          ),
        ),

        // ── Naps ─────────────────────────────────────────────
        if (naps.isNotEmpty) ...[
          const SizedBox(height: HelioSpacing.lg),
          Text('NAPS (${naps.length})', style: HelioTypography.sectionTitle),
          const SizedBox(height: HelioSpacing.sm),
          ...naps.map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: HelioSpacing.sm),
              child: HelioSurfaceCard(
                padding: const EdgeInsets.all(HelioSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          formatWorkoutTime(n.startedAt),
                          style: HelioTypography.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          formatSleepMins(n.totalMins),
                          style: HelioTypography.bodyMuted,
                        ),
                      ],
                    ),
                    if (n.stages.isNotEmpty) ...[
                      const SizedBox(height: HelioSpacing.md),
                      SleepHypnogramChart(stages: n.stages),
                    ] else ...[
                      const SizedBox(height: HelioSpacing.sm),
                      SleepStageRow(
                        label: 'Deep',
                        color: HelioColors.sleepDeep,
                        minutes: n.deepMins,
                        totalMinutes: n.totalMins,
                      ),
                      SleepStageRow(
                        label: 'REM',
                        color: HelioColors.sleepRem,
                        minutes: n.remMins,
                        totalMinutes: n.totalMins,
                      ),
                      SleepStageRow(
                        label: 'Light',
                        color: HelioColors.sleepLight,
                        minutes: n.lightMins,
                        totalMinutes: n.totalMins,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],

        // ── Detail description ──────────────────────────────
        const SizedBox(height: HelioSpacing.sm),
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.lg),
          child: Text(
            MetricCatalog.byId('sleep')!.detail,
            style: HelioTypography.bodyMuted,
          ),
        ),
      ],
    );
  }
}
