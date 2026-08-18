import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/sport_icons.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/widgets/activity/activity_feed_item.dart';
import 'package:heliolytics/widgets/home_activity_row.dart';

class HomeActivitiesSection extends StatelessWidget {
  final DayBundle bundle;

  const HomeActivitiesSection({super.key, required this.bundle});

  @override
  Widget build(BuildContext context) {
    final activities = _activities();
    if (activities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                bundle.day.dayKey == todayDayKey()
                    ? "TODAY'S ACTIVITIES"
                    : 'ACTIVITIES',
                style: HelioTypography.capsLabel.copyWith(fontSize: 11),
              ),
            ),
            Icon(Icons.open_in_full, size: 16, color: HelioColors.textMuted),
          ],
        ),
        const SizedBox(height: HelioSpacing.sm),
        HelioSurfaceCard(
          padding: const EdgeInsets.all(HelioSpacing.md),
          child: Column(
            children: [
              ...activities.map((activity) {
                return HomeActivityRow(
                  icon: sportIcon(activity.sportType, name: activity.title),
                  label: activity.title,
                  duration: formatDurationSec(activity.durationSec),
                  start: activity.startedAt,
                  end: activity.startedAt.add(
                    Duration(seconds: activity.durationSec),
                  ),
                  color: HelioColors.strainBlue,
                  onTap: () =>
                      context.push('/activity/detail', extra: activity.payload),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  List<ActivityFeedItem> _activities() {
    final items = [
      ...bundle.workouts.map(ActivityFeedItem.workout),
      ...bundle.activitySessions.map(ActivityFeedItem.session),
    ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return items.take(2).toList();
  }
}
