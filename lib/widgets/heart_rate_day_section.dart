import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_metric_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/providers/live_hr_provider.dart';
import 'package:heliolytics/utils/hr_chart_samples.dart';
import 'package:heliolytics/widgets/heart_rate_bpm_hero.dart';
import 'package:heliolytics/widgets/metric_stats_row.dart';
import 'package:heliolytics/widgets/minute_series_chart.dart';

class HeartRateDaySection extends ConsumerWidget {
  final DayMetric day;
  final String dayKey;

  const HeartRateDaySection({
    super.key,
    required this.day,
    required this.dayKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveHrProvider);
    final detail = ref.watch(detailMetricsProvider).valueOrNull;
    final hr = detail?.heartRateFor(dayKey) ?? const [];
    final latest = hr.isEmpty ? null : hr.last;
    final syncedBpm = latest?.bpm ?? day.restingHr;
    final syncedLabel = latest != null ? 'LATEST BPM' : 'RESTING BPM';

    final isLive = live.isLive && live.bpm != null;
    final heroBpm = isLive ? live.bpm! : (syncedBpm ?? 64);
    final heroLabel = isLive ? 'LIVE BPM' : syncedLabel;
    final heroAt = isLive ? live.sampledAt : latest?.sampledAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => context.push('/metric/$dayKey/continuous_hr'),
          child: HeartRateBpmHero(
            bpm: heroBpm,
            label: heroLabel,
            at: heroAt,
            isLive: isLive,
          ),
        ),
        const SizedBox(height: HelioSpacing.xl),
        _sectionHeader(),
        const SizedBox(height: HelioSpacing.md),
        if (isLive && live.recentSamples.isNotEmpty) ...[
          _liveMiniChart(live),
          const SizedBox(height: HelioSpacing.md),
        ],
        if (hr.isEmpty && !isLive)
          HelioSurfaceCard(
            padding: const EdgeInsets.all(HelioSpacing.lg),
            child: Text(
              'No continuous HR for this day. Enable PPG on the strap and sync again.',
              style: HelioTypography.bodyMuted,
            ),
          )
        else if (hr.isNotEmpty) ...[
          MetricStatsRow(stats: MetricStats.fromHeartRate(hr), unit: 'bpm'),
          const SizedBox(height: HelioSpacing.sm),
          HelioSurfaceCard(
            padding: const EdgeInsets.all(HelioSpacing.sm),
            child: MinuteSeriesChart(
              samples: heartRateAsChartSamples(hr),
              color: HelioMetricColors.restingHr,
              unit: 'bpm',
              height: 220,
              maxPoints: 900,
              showDots: false,
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader() {
    return Row(
      children: [
        Text('CONTINUOUS HEART RATE', style: HelioTypography.sectionTitle),
        const SizedBox(width: HelioSpacing.sm),
        const Icon(Icons.info_outline, size: 14, color: HelioColors.textMuted),
      ],
    );
  }

  Widget _liveMiniChart(LiveHrState live) {
    final samples = live.recentSamples
        .map(
          (s) => HealthSample(
            metric: 'hr',
            dayKey: dayKey,
            sampledAt: s.at,
            value: s.bpm.toDouble(),
          ),
        )
        .toList();
    return HelioSurfaceCard(
      padding: const EdgeInsets.all(HelioSpacing.sm),
      child: MinuteSeriesChart(
        samples: samples,
        color: HelioColors.recoveryLow,
        unit: 'bpm',
        height: 100,
        maxPoints: live.recentSamples.length,
        showDots: true,
      ),
    );
  }
}
