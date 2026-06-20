import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/utils/sport_icons.dart';
import 'package:heliolytics/utils/sport_labels.dart';
import 'package:heliolytics/design_system/components/helio_empty_state.dart';
import 'package:heliolytics/design_system/components/helio_loading.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/widgets/activity_row.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/providers/live_health_provider.dart';
import 'package:heliolytics/models/activity_detail_payload.dart';
import 'package:heliolytics/providers/helio_nav_provider.dart';
import 'package:heliolytics/widgets/error_view.dart';

class ActivityHubScreen extends ConsumerStatefulWidget {
  const ActivityHubScreen({super.key});

  @override
  ConsumerState<ActivityHubScreen> createState() => _ActivityHubScreenState();
}

class _ActivityHubScreenState extends ConsumerState<ActivityHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(liveHealthProvider);
    final workouts = ref.watch(workoutsByDayProvider);
    final sessions = ref.watch(activitySessionsByDayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(HelioSpacing.lg, HelioSpacing.lg, HelioSpacing.lg, 0),
          child: Text('ACTIVITY', style: HelioTypography.sectionTitle),
        ),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'WORKOUTS'),
            Tab(text: 'AUTO SESSIONS'),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(liveHealthProvider.notifier).reload(),
            child: health.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  HelioLoading(),
                ],
              ),
              error: (e, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [ErrorView(error: e, onRetry: () => ref.invalidate(liveHealthProvider))],
              ),
              data: (_) => TabBarView(
                controller: _tabs,
                children: [
                  _workoutList(workouts),
                  _sessionList(sessions),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _workoutList(Map<String, List<WorkoutMetric>> grouped) {
    if (grouped.isEmpty) return _empty(true);
    return _dayList(grouped, isWorkout: true);
  }

  Widget _sessionList(Map<String, List<ActivitySessionMetric>> grouped) {
    if (grouped.isEmpty) return _empty(false);
    return _dayList(grouped, isWorkout: false);
  }

  Widget _empty(bool workouts) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        HelioEmptyState(
          icon: workouts ? Icons.sports_outlined : Icons.directions_walk,
          title: workouts ? 'No workouts yet' : 'No auto sessions',
          message: workouts
              ? 'Manual sports recordings appear here after sync.'
              : 'Strap-detected activities appear here after sync.',
          actionLabel: 'Open Settings',
          onAction: () => goToHelioSettings(ref),
        ),
      ],
    );
  }

  Widget _dayList(Map<String, List<dynamic>> grouped, {required bool isWorkout}) {
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(HelioSpacing.lg),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final day = days[i];
        final items = grouped[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: HelioSpacing.sm),
              child: Text(formatDayLabel(day), style: HelioTypography.capsLabel),
            ),
            ...items.map((item) {
              final title = _title(item, isWorkout);
              return ActivityRow(
                icon: _icon(item, title),
                title: title,
                duration: formatDurationSec(item.durationSec),
                timeRange: formatWorkoutTime(item.startedAt),
                onTap: () => _openDetail(item, isWorkout),
              );
            }),
            const SizedBox(height: HelioSpacing.md),
          ],
        );
      },
    );
  }

  String _title(dynamic item, bool isWorkout) {
    final name = item.sportName as String;
    if (name.isNotEmpty) return name;
    return sportLabel(item.sportType as int);
  }

  IconData _icon(dynamic item, String title) =>
      sportIcon(item.sportType as int, name: title);

  void _openDetail(dynamic item, bool isWorkout) {
    final payload = isWorkout
        ? ActivityDetailPayload.workout(item as WorkoutMetric)
        : ActivityDetailPayload.session(item as ActivitySessionMetric);
    context.push('/activity/detail', extra: payload);
  }
}
