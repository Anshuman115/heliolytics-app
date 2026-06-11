import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/core/config/api_config_storage.dart';
import 'package:heliolytics/core/network/api_dio.dart';
import 'package:heliolytics/core/utils/error_messages.dart';
import 'package:heliolytics/core/utils/logger.dart';
import 'package:heliolytics/features/ble_discovery/data/session_store.dart';
import 'package:heliolytics/features/cloud_sync/presentation/providers/cloud_sync_provider.dart';
import 'package:heliolytics/features/health_data/data/api/metrics_api_client.dart';
import 'package:heliolytics/features/health_data/domain/entities/cloud_metrics_snapshot.dart';
import 'package:heliolytics/features/health_data/domain/entities/day_metric.dart';
import 'package:heliolytics/features/health_data/domain/entities/sync_coverage.dart';

final metricsApiClientProvider = Provider<MetricsApiClient>((ref) {
  return MetricsApiClient(
    ref.watch(apiConfigStorageProvider),
    dio: ref.watch(apiDioProvider),
  );
});

final liveHealthProvider =
    AsyncNotifierProvider<LiveHealthNotifier, CloudMetricsSnapshot?>(
  LiveHealthNotifier.new,
);

final workoutsByDayProvider = Provider<Map<String, List<WorkoutMetric>>>((ref) {
  final snap = ref.watch(liveHealthProvider).valueOrNull;
  if (snap == null) return {};
  final out = <String, List<WorkoutMetric>>{};
  for (final w in snap.workouts) {
    out.putIfAbsent(w.dayKey, () => []).add(w);
  }
  for (final list in out.values) {
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }
  return out;
});

final activitySessionsByDayProvider = Provider<Map<String, List<ActivitySessionMetric>>>((ref) {
  final snap = ref.watch(liveHealthProvider).valueOrNull;
  if (snap == null) return {};
  final out = <String, List<ActivitySessionMetric>>{};
  for (final s in snap.activitySessions) {
    out.putIfAbsent(s.dayKey, () => []).add(s);
  }
  for (final list in out.values) {
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }
  return out;
});

class LiveHealthNotifier extends AsyncNotifier<CloudMetricsSnapshot?> {
  @override
  Future<CloudMetricsSnapshot?> build() => _load();

  Future<CloudMetricsSnapshot?> _load() async {
    final configured = await ref.watch(apiConfiguredProvider.future);
    if (!configured) return null;

    final client = ref.watch(metricsApiClientProvider);
    final days = await client.fetchDays();
    final sleep = await _optional(client.fetchSleep(), 'sleep');
    final workouts = await _optional(client.fetchWorkouts(), 'workouts');
    final activitySessions = await _optional(client.fetchActivitySessions(), 'activitySessions');
    final temperature = await _optional(client.fetchTemperature(), 'temperature');
    final series = await _optional(client.fetchSeries(), 'series');
    final coverage = await _optionalCoverage(client.fetchCoverage());

    final store = await ref.watch(sessionStoreProvider.future);
    final ids = await store.listSessions();
    DateTime? syncedAt = coverage?.lastIngestAt ?? coverage?.dataThrough;
    int? battery;
    if (syncedAt == null && ids.isNotEmpty) {
      final s = await store.readSessionJson(ids.first);
      syncedAt = (s.endedAt ?? s.startedAt).toLocal();
      battery = s.batteryPercent;
    } else if (ids.isNotEmpty) {
      battery = (await store.readSessionJson(ids.first)).batteryPercent;
    }
    return CloudMetricsSnapshot(
      days: days,
      sleep: sleep,
      workouts: workouts,
      activitySessions: activitySessions,
      temperature: temperature,
      series: series,
      lastSyncedAt: syncedAt,
      batteryPercent: battery,
    );
  }

  Future<List<T>> _optional<T>(Future<List<T>> future, String label) async {
    try {
      return await future;
    } catch (e) {
      appLog('$label: ${friendlyError(e)}', tag: 'metrics');
      return [];
    }
  }

  Future<SyncCoverage?> _optionalCoverage(Future<SyncCoverage> future) async {
    try {
      return await future;
    } catch (e) {
      appLog('coverage: ${friendlyError(e)}', tag: 'metrics');
      return null;
    }
  }

  Future<void> reload() async {
    final prev = state;
    state = const AsyncLoading<CloudMetricsSnapshot?>().copyWithPrevious(prev);
    state = await AsyncValue.guard(_load);
  }
}
