import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/models/metric_catalog.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/sport_icons.dart';
import 'package:heliolytics/widgets/activity/activity_feed_item.dart';
import 'package:heliolytics/widgets/activity/activity_strain_hero.dart';
import 'package:heliolytics/widgets/activity_row.dart';
import 'package:heliolytics/widgets/strain_metric_section.dart';
import 'package:heliolytics/widgets/metric_trend_section.dart';

class ActivityOverviewBody extends StatelessWidget {
  const ActivityOverviewBody({
    super.key,
    required this.bundle,
    required this.heartRate,
  });

  final DayBundle bundle;
  final List<HeartRateSample> heartRate;

  @override
  Widget build(BuildContext context) {
    final items = _items();
    final dayKey = bundle.day.dayKey;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        HelioSpacing.lg,
        HelioSpacing.md,
        HelioSpacing.lg,
        shellContentBottomPadding,
      ),
      children: [
        const SizedBox(height: HelioSpacing.sm),
        ActivityStrainHero(
          day: bundle.day,
          onTap: () => context.push('/metric/$dayKey/pai'),
        ),
        const SizedBox(height: HelioSpacing.xl),
        StrainMetricSection(
          definition: MetricCatalog.byId('pai')!,
          day: bundle.day,
          heartRate: heartRate,
        ),
        const SizedBox(height: HelioSpacing.xxl),
        Text(
          dayKey == todayDayKey() ? "TODAY'S ACTIVITIES" : 'ACTIVITIES',
          style: HelioTypography.sectionTitle,
        ),
        const SizedBox(height: HelioSpacing.md),
        if (items.isEmpty)
          _empty()
        else
          ...items.map((item) => _row(context, item)),
        const SizedBox(height: HelioSpacing.xxl),
        Text('WEEKLY TRENDS', style: HelioTypography.sectionTitle),
        const SizedBox(height: HelioSpacing.md),
        MetricTrendSection(
          definition: MetricCatalog.byId('pai')!,
          anchorDayKey: dayKey,
        ),
      ],
    );
  }

  List<ActivityFeedItem> _items() {
    final items = <ActivityFeedItem>[
      for (final workout in bundle.workouts) ActivityFeedItem.workout(workout),
      for (final session in bundle.activitySessions)
        ActivityFeedItem.session(session),
    ];
    items.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return items;
  }

  Widget _empty() => HelioSurfaceCard(
    padding: const EdgeInsets.all(HelioSpacing.xl),
    child: Column(
      children: [
        const Icon(
          Icons.directions_run,
          color: HelioColors.textMuted,
          size: 30,
        ),
        const SizedBox(height: HelioSpacing.sm),
        Text('No activities recorded', style: HelioTypography.body),
        const SizedBox(height: 3),
        Text(
          'Synced workouts and auto sessions appear here.',
          style: HelioTypography.bodyMuted,
        ),
      ],
    ),
  );

  Widget _row(BuildContext context, ActivityFeedItem item) => ActivityRow(
    icon: sportIcon(item.sportType, name: item.title),
    title: item.title,
    duration: formatDurationSec(item.durationSec),
    timeRange: formatWorkoutTime(item.startedAt),
    kind: item.isWorkout ? 'WORKOUT' : 'AUTO SESSION',
    onTap: () => context.push('/activity/detail', extra: item.payload),
  );
}
