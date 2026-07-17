import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/hr_chart_samples.dart';
import 'package:heliolytics/utils/hr_zones.dart';
import 'package:heliolytics/utils/sport_icons.dart';
import 'package:heliolytics/utils/sport_labels.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/components/helio_top_bar.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/models/activity_detail_payload.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/widgets/hr_zone_bars.dart';
import 'package:heliolytics/widgets/minute_series_chart.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, this.extra});

  final Object? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = extra ?? GoRouterState.of(context).extra;
    if (payload is! ActivityDetailPayload) {
      return _shell(context, null, const Center(child: Text('Activity data unavailable')));
    }
    final w = payload.workout;
    final s = payload.session;
    final view = w != null
        ? _WorkoutView(w)
        : s != null
            ? _SessionView(s)
            : null;
    if (view == null) {
      return _shell(context, null, const Center(child: Text('Activity not found')));
    }

    final detail = ref.watch(detailMetricsProvider).valueOrNull;
    final hr = detail == null
        ? const <HeartRateSample>[]
        : _inWindow(detail.heartRateFor(view.dayKey), view.start, view.durationSec);

    return _shell(context, view.title, _content(view, hr));
  }

  Widget _shell(BuildContext context, String? title, Widget body) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HelioTopBar(showBack: true, onBack: () => context.pop(), title: title),
      body: body,
    );
  }

  Widget _content(_ActivityView view, List<HeartRateSample> hr) {
    final zones = computeHrZones(hr, maxHr: view.maxHr);
    return ListView(
      padding: const EdgeInsets.all(HelioSpacing.lg),
      children: [
        _header(view),
        const SizedBox(height: HelioSpacing.xl),
        _heroStats(view),
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
          HrZoneBars(breakdown: zones),
        ],
        const SizedBox(height: HelioSpacing.xl),
        Text('KEY STATISTICS', style: HelioTypography.sectionTitle),
        const SizedBox(height: HelioSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: HelioSpacing.sm,
          mainAxisSpacing: HelioSpacing.sm,
          childAspectRatio: 1.9,
          children: [for (final s in view.keyStats) _StatCard(stat: s)],
        ),
      ],
    );
  }

  Widget _header(_ActivityView view) {
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
          child: Icon(view.icon, size: 26, color: HelioColors.strainBlue),
        ),
        const SizedBox(width: HelioSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(view.title.toUpperCase(),
                  style: HelioTypography.scoreMedium.copyWith(fontSize: 20)),
              const SizedBox(height: 2),
              Text(view.subtitle, style: HelioTypography.bodyMuted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroStats(_ActivityView view) {
    final left = view.avgHr != null
        ? _ActivityStat(Icons.favorite, 'Avg HR', '${view.avgHr}', 'bpm')
        : _ActivityStat(Icons.timer_outlined, 'Duration',
            formatDurationSec(view.durationSec), '');
    final right = view.calories != null
        ? _ActivityStat(Icons.local_fire_department, 'Calories', '${view.calories}', 'cal')
        : _ActivityStat(Icons.trending_up, 'Max HR',
            view.maxHr != null ? '${view.maxHr}' : '—', 'bpm');
    return Row(
      children: [
        Expanded(child: _BigStat(stat: left)),
        const SizedBox(width: HelioSpacing.sm),
        Expanded(child: _BigStat(stat: right)),
      ],
    );
  }
}

List<HeartRateSample> _inWindow(List<HeartRateSample> hr, DateTime start, int durationSec) {
  final end = start.add(Duration(seconds: durationSec));
  return hr
      .where((h) => !h.sampledAt.isBefore(start) && !h.sampledAt.isAfter(end))
      .toList();
}

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
              Text(stat.label.toUpperCase(),
                  style: HelioTypography.capsLabel.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: HelioSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(stat.value, style: HelioTypography.scoreMedium.copyWith(fontSize: 28)),
              if (stat.unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(stat.unit,
                      style: HelioTypography.bodyMuted.copyWith(fontSize: 12)),
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
              Text(stat.label.toUpperCase(),
                  style: HelioTypography.capsLabel.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: HelioSpacing.xs),
          Text('${stat.value}${stat.unit.isNotEmpty ? ' ${stat.unit}' : ''}',
              style: HelioTypography.scoreMedium.copyWith(fontSize: 20)),
        ],
      ),
    );
  }
}

abstract class _ActivityView {
  String get title;
  String get subtitle;
  String get dayKey;
  DateTime get start;
  int get durationSec;
  int? get avgHr;
  int? get maxHr;
  int? get calories;
  IconData get icon;
  List<_ActivityStat> get keyStats;
}

String _timeRange(DateTime start, int durationSec) {
  final fmt = DateFormat.jm();
  final end = start.add(Duration(seconds: durationSec));
  return '${fmt.format(start.toLocal())} – ${fmt.format(end.toLocal())}';
}

class _WorkoutView implements _ActivityView {
  _WorkoutView(this.w);
  final WorkoutMetric w;

  @override
  String get title => w.sportName.isNotEmpty ? w.sportName : sportLabel(w.sportType);
  @override
  String get subtitle => _timeRange(w.startedAt, w.durationSec);
  @override
  String get dayKey => w.dayKey;
  @override
  DateTime get start => w.startedAt;
  @override
  int get durationSec => w.durationSec;
  @override
  int? get avgHr => w.avgHr;
  @override
  int? get maxHr => w.maxHr;
  @override
  int? get calories => w.calories;
  @override
  IconData get icon => sportIcon(w.sportType, name: title);
  @override
  List<_ActivityStat> get keyStats => [
        _ActivityStat(Icons.timer_outlined, 'Duration', formatDurationSec(w.durationSec), ''),
        if (w.maxHr != null) _ActivityStat(Icons.trending_up, 'Max HR', '${w.maxHr}', 'bpm'),
        if (w.calories != null)
          _ActivityStat(Icons.local_fire_department_outlined, 'Calories', '${w.calories}', 'cal'),
        if (w.avgHr != null) _ActivityStat(Icons.favorite_outline, 'Avg HR', '${w.avgHr}', 'bpm'),
      ];
}

class _SessionView implements _ActivityView {
  _SessionView(this.s);
  final ActivitySessionMetric s;

  @override
  String get title => s.sportName.isNotEmpty ? s.sportName : sportLabel(s.sportType);
  @override
  String get subtitle => _timeRange(s.startedAt, s.durationSec);
  @override
  String get dayKey => s.dayKey;
  @override
  DateTime get start => s.startedAt;
  @override
  int get durationSec => s.durationSec;
  @override
  int? get avgHr => s.avgHr;
  @override
  int? get maxHr => s.maxHr;
  @override
  int? get calories => s.calories;
  @override
  IconData get icon => sportIcon(s.sportType, name: title);
  @override
  List<_ActivityStat> get keyStats => [
        _ActivityStat(Icons.timer_outlined, 'Duration', formatDurationSec(s.durationSec), ''),
        if (s.maxHr != null) _ActivityStat(Icons.trending_up, 'Max HR', '${s.maxHr}', 'bpm'),
        if (s.calories != null)
          _ActivityStat(Icons.local_fire_department_outlined, 'Calories', '${s.calories}', 'cal'),
        if (s.avgHr != null) _ActivityStat(Icons.favorite_outline, 'Avg HR', '${s.avgHr}', 'bpm'),
      ];
}
