import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_metric_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/providers/live_hr_provider.dart';
import 'package:heliolytics/utils/hr_chart_samples.dart';
import 'package:heliolytics/widgets/metric_stats_row.dart';
import 'package:heliolytics/widgets/minute_series_chart.dart';

class HeartRateDaySection extends ConsumerWidget {
  final String dayKey;

  const HeartRateDaySection({super.key, required this.dayKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveHrProvider);
    final detail = ref.watch(detailMetricsProvider(dayKey)).valueOrNull;
    final hr = detail?.heartRateFor(dayKey) ?? const [];
    final isLive = live.isLive && live.bpm != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
