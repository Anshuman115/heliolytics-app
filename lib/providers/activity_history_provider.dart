import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/activity_metric.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/services/network/metrics_api_transport.dart';

/// One `/activities` call, partitioned by kind without hiding failures.
class ActivityHistory {
  const ActivityHistory({this.activities = const []});

  final List<ActivityMetric> activities;

  List<ActivityMetric> get workouts =>
      activities.where((a) => a.isWorkout).toList();

  List<ActivityMetric> get autoActivities =>
      activities.where((a) => !a.isWorkout).toList();
}

final activityHistoryProvider = FutureProvider<ActivityHistory>((ref) async {
  final configured = await ref.watch(apiConfiguredProvider.future);
  if (!configured) {
    throw const MetricsApiException(
      type: MetricsApiFailureType.notConfigured,
      path: '/api/activities',
      message: cloudApiRequiredBeforeSyncMessage,
    );
  }
  final activities = await ref
      .read(metricsApiClientProvider)
      .fetchActivities(windowDays: devWorkoutFetchDays);
  return ActivityHistory(activities: activities);
});

final activitiesByDayProvider = Provider<Map<String, List<ActivityMetric>>>((
  ref,
) {
  final history = ref.watch(activityHistoryProvider).valueOrNull;
  if (history == null) return {};
  final out = <String, List<ActivityMetric>>{};
  for (final activity in history.activities) {
    out.putIfAbsent(activity.dayKey, () => []).add(activity);
  }
  for (final list in out.values) {
    list.sort((a, b) => a.startedAt.compareTo(b.startedAt));
  }
  return out;
});
