import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/theme/app_spacing.dart';
import 'package:heliolytics/core/theme/app_theme.dart';
import 'package:heliolytics/core/utils/formatters.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/presentation/providers/live_health_provider.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/activity_session_tile.dart';
import 'package:heliolytics/features/health_data/presentation/widgets/workout_tile.dart';
import 'package:heliolytics/shared/providers/shell_tab_provider.dart';
import 'package:heliolytics/shared/widgets/empty_state_view.dart';
import 'package:heliolytics/shared/widgets/error_view.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> with SingleTickerProviderStateMixin {
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
    final wCount = workouts.values.fold<int>(0, (s, l) => s + l.length);
    final sCount = sessions.values.fold<int>(0, (s, l) => s + l.length);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Activity'),
              background: DecoratedBox(decoration: BoxDecoration(gradient: headerGradient())),
            ),
            bottom: TabBar(
              controller: _tabs,
              tabs: [
                Tab(text: 'Workouts ($wCount)'),
                Tab(text: 'Auto ($sCount)'),
              ],
            ),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: () => ref.read(liveHealthProvider.notifier).reload(),
          child: health.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(liveHealthProvider)),
            data: (_) => TabBarView(
              controller: _tabs,
              children: [
                _workoutList(ref, workouts),
                _sessionList(ref, sessions),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _workoutList(WidgetRef ref, Map<String, List<WorkoutMetric>> grouped) {
    if (grouped.isEmpty) return _empty(ref, true);
    return _dayList(grouped.keys.toList()..sort((a, b) => b.compareTo(a)), (day) {
      return grouped[day]!.map((w) => WorkoutTile(workout: w)).toList();
    });
  }

  Widget _sessionList(WidgetRef ref, Map<String, List<ActivitySessionMetric>> grouped) {
    if (grouped.isEmpty) return _empty(ref, false);
    return _dayList(grouped.keys.toList()..sort((a, b) => b.compareTo(a)), (day) {
      return grouped[day]!.map((s) => ActivitySessionTile(session: s)).toList();
    });
  }

  Widget _empty(WidgetRef ref, bool workouts) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        EmptyStateView(
          icon: workouts ? Icons.sports_outlined : Icons.directions_walk,
          title: workouts ? 'No workouts yet' : 'No auto-detected sessions',
          message: workouts
              ? 'Manual sports recordings (0x05) appear here.'
              : 'Strap-detected walks and activities (0x3B) appear here.',
          actionLabel: 'Open Settings',
          onAction: () => goToSettingsTab(ref),
        ),
      ],
    );
  }

  Widget _dayList(List<String> days, List<Widget> Function(String day) tiles) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final day = days[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
              child: Text(formatDayLabel(day), style: Theme.of(context).textTheme.titleSmall),
            ),
            ...tiles(day),
          ],
        );
      },
    );
  }
}
