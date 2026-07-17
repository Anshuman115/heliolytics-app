import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/live_health_provider.dart';

class ActivityHistory {
  final List<WorkoutMetric> workouts;
  final List<ActivitySessionMetric> activitySessions;
  const ActivityHistory({this.workouts = const [], this.activitySessions = const []});
}

final activityHistoryProvider = FutureProvider<ActivityHistory>((ref) async {
  final configured = await ref.watch(apiConfiguredProvider.future);
  if (!configured) return const ActivityHistory();
  final client = ref.read(metricsApiClientProvider);
  final (workouts, sessions) = await (
    client.fetchWorkouts(),
    client.fetchActivitySessions(),
  ).wait;
  return ActivityHistory(workouts: workouts, activitySessions: sessions);
});

final workoutsByDayProvider = Provider<Map<String, List<WorkoutMetric>>>((ref) {
  final history = ref.watch(activityHistoryProvider).valueOrNull;
  if (history == null) return {};
  final out = <String, List<WorkoutMetric>>{};
  for (final w in history.workouts) {
    out.putIfAbsent(w.dayKey, () => []).add(w);
  }
  for (final list in out.values) {
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }
  return out;
});

final activitySessionsByDayProvider = Provider<Map<String, List<ActivitySessionMetric>>>((ref) {
  final history = ref.watch(activityHistoryProvider).valueOrNull;
  if (history == null) return {};
  final out = <String, List<ActivitySessionMetric>>{};
  for (final s in history.activitySessions) {
    out.putIfAbsent(s.dayKey, () => []).add(s);
  }
  for (final list in out.values) {
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }
  return out;
});
