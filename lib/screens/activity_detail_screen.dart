import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/components/helio_bottom_nav.dart';
import 'package:heliolytics/design_system/components/helio_empty_state.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/activity_detail_payload.dart';
import 'package:heliolytics/models/activity_metric.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/providers/health_data_refresh_coordinator.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/hr_chart_samples.dart';
import 'package:heliolytics/utils/hr_zones.dart';
import 'package:heliolytics/utils/sport_icons.dart';
import 'package:heliolytics/utils/sport_labels.dart';
import 'package:heliolytics/widgets/hr_zone_bars.dart';
import 'package:heliolytics/widgets/minute_series_chart.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, this.extra});

  final Object? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = extra ?? GoRouterState.of(context).extra;
    if (payload is! ActivityDetailPayload) {
      return _shell(
        context,
        null,
        const Center(child: Text('Activity data unavailable')),
      );
    }
    final activity = payload.activity;
    final title = activity.sportName.isEmpty
        ? sportLabel(activity.sportType)
        : activity.sportName;
    final detail = ref.watch(detailMetricsProvider(activity.dayKey));
    return _shell(
      context,
      title,
      _content(
        activity,
        detail,
        onRetry: () => ref
            .read(healthDataRefreshCoordinatorProvider)
            .retryDay(activity.dayKey, details: true),
      ),
    );
  }

  Widget _shell(BuildContext context, String? title, Widget body) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HelioTopBar(
        showBack: true,
        onBack: () => context.pop(),
        title: title,
      ),
      body: body,
      bottomNavigationBar: HelioBottomNav(
        index: 2,
        showTabs: false,
        onChanged: (_) {},
        onOrbTap: () => context.push('/profile/view'),
      ),
    );
  }

  Widget _content(
    ActivityMetric activity,
    AsyncValue<DetailMetrics> detail, {
    required VoidCallback onRetry,
  }) {
    final hr = detail.valueOrNull == null
        ? const <HeartRateSample>[]
        : _inWindow(
            detail.valueOrNull!.heartRateFor(activity.dayKey),
            activity.startedAt,
            activity.endedAt,
          );
    final zones = computeHrZones(hr, maxHr: activity.maxHr);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        HelioSpacing.lg,
        HelioSpacing.lg,
        HelioSpacing.lg,
        shellContentBottomPadding,
      ),
      children: [
        _header(activity),
        const SizedBox(height: HelioSpacing.xl),
        _heroStats(activity),
        if (!activity.hasDetail) ...[
          const SizedBox(height: HelioSpacing.lg),
          Text(
            'No recorded workout detail for this activity.',
            style: HelioTypography.bodyMuted,
          ),
        ],
        if (detail.isLoading) ...[
          const SizedBox(height: HelioSpacing.xl),
          const HelioLoading(message: 'Loading heart-rate readings…'),
        ] else if (detail.hasError) ...[
          const SizedBox(height: HelioSpacing.xl),
          HelioEmptyState(
            icon: Icons.error_outline,
            title: 'Heart rate unavailable',
            message: detail.error.toString(),
            actionLabel: 'Retry',
            onAction: onRetry,
          ),
        ] else if (hr.isEmpty) ...[
          const SizedBox(height: HelioSpacing.xl),
          const HelioEmptyState(
            icon: Icons.monitor_heart_outlined,
            title: 'No heart-rate readings',
            message: 'The strap did not record heart rate for this activity.',
          ),
        ],
        if (hr.isNotEmpty) ...[
          const SizedBox(height: HelioSpacing.xl),
          Text('HEART RATE', style: HelioTypography.sectionTitle),
          const SizedBox(height: HelioSpacing.sm),
          HelioSurfaceCard(
            padding: const EdgeInsets.all(HelioSpacing.sm),
            child: MinuteSeriesChart(
              samples: heartRateAsChartSamples(hr),
              color: HelioColors.recoveryLow,
              unit: 'bpm',
              height: 200,
              maxPoints: 480,
              showDots: false,
            ),
          ),
        ],
        if (zones.hasData) ...[
          const SizedBox(height: HelioSpacing.xl),
          Text('HEART RATE ZONES', style: HelioTypography.sectionTitle),
          const SizedBox(height: HelioSpacing.md),
          HelioSurfaceCard(
            padding: const EdgeInsets.all(HelioSpacing.md),
            child: HrZoneBars(breakdown: zones),
          ),
        ],
        if (_keyStats(activity).isNotEmpty) ...[
          const SizedBox(height: HelioSpacing.xl),
          Text('KEY STATISTICS', style: HelioTypography.sectionTitle),
          const SizedBox(height: HelioSpacing.md),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _keyStats(activity).length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: HelioSpacing.sm),
              itemBuilder: (_, index) => SizedBox(
                width: 205,
                child: _StatCard(stat: _keyStats(activity)[index]),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _header(ActivityMetric activity) {
    final title = activity.sportName.isEmpty
        ? sportLabel(activity.sportType)
        : activity.sportName;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: HelioColors.strainBlue.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: HelioColors.strainBlue.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            sportIcon(activity.sportType, name: title),
            size: 26,
            color: HelioColors.strainBlue,
          ),
        ),
        const SizedBox(width: HelioSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${activity.kind.label} · ${_timeRange(activity)}',
                style: HelioTypography.bodyMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroStats(ActivityMetric activity) {
    final stats = <_ActivityStat>[
      if (activity.avgHr != null)
        _ActivityStat(Icons.favorite, 'Avg HR', '${activity.avgHr}', 'bpm'),
      _ActivityStat(
        Icons.timer_outlined,
        'Duration',
        _formatActivityDuration(activity.durationSec),
        '',
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.take(2).length; i++) ...[
          if (i > 0) const SizedBox(width: HelioSpacing.sm),
          Expanded(child: _BigStat(stat: stats[i])),
        ],
      ],
    );
  }

  List<_ActivityStat> _keyStats(ActivityMetric activity) => [
    if (activity.maxHr != null)
      _ActivityStat(Icons.trending_up, 'Max HR', '${activity.maxHr}', 'bpm'),
    if (activity.minHr != null)
      _ActivityStat(Icons.trending_down, 'Min HR', '${activity.minHr}', 'bpm'),
    if (activity.calories != null)
      _ActivityStat(
        Icons.local_fire_department,
        'Calories',
        '${activity.calories}',
        'cal',
      ),
    if (activity.steps != null)
      _ActivityStat(Icons.directions_walk, 'Steps', '${activity.steps}', ''),
  ];
}

String _formatActivityDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remaining = seconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}

/// Half-open window: the start is included, the end is not.
List<HeartRateSample> _inWindow(
  List<HeartRateSample> hr,
  DateTime start,
  DateTime end,
) => hr
    .where((h) => !h.sampledAt.isBefore(start) && h.sampledAt.isBefore(end))
    .toList();

String _timeRange(ActivityMetric activity) =>
    '${formatTimeOfDay(activity.startedAt)} to '
    '${formatTimeOfDay(activity.endedAt)}';

class _ActivityStat {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  const _ActivityStat(this.icon, this.label, this.value, this.unit);
}

class _BigStat extends StatelessWidget {
  final _ActivityStat stat;
  const _BigStat({required this.stat});

  @override
  Widget build(BuildContext context) {
    return HelioSurfaceCard(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(stat.icon, size: 15, color: HelioColors.strainBlue),
              const SizedBox(width: 6),
              Text(
                stat.label.toUpperCase(),
                style: HelioTypography.capsLabel.copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: HelioSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stat.value,
                style: HelioTypography.scoreMedium.copyWith(fontSize: 28),
              ),
              if (stat.unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    stat.unit,
                    style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _ActivityStat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return HelioSurfaceCard(
      padding: const EdgeInsets.all(HelioSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(stat.icon, size: 15, color: HelioColors.strainBlue),
              const SizedBox(width: 6),
              Text(
                stat.label.toUpperCase(),
                style: HelioTypography.capsLabel.copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: HelioSpacing.xs),
          Text(
            '${stat.value}${stat.unit.isNotEmpty ? ' ${stat.unit}' : ''}',
            style: HelioTypography.scoreMedium.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
