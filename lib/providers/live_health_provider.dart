import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:heliolytics/services/ble/auth/auth_key_storage.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/network/api_dio.dart';
import 'package:heliolytics/utils/error_messages.dart';
import 'package:heliolytics/utils/app_logger.dart';
import 'package:heliolytics/services/session_store.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/services/metrics_api_client.dart';
import 'package:heliolytics/models/cloud_metrics_snapshot.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/models/sync_coverage.dart';
import 'package:heliolytics/models/temp_sample.dart';

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

/// Heavy per-minute datasets (series, continuous HR, temperature) used only by
/// detail/monitor screens. Kept out of [liveHealthProvider] so Home/Sleep/
/// Activity don't pull large payloads; loads lazily on first watch and is
/// cached for the session. Invalidated alongside liveHealthProvider on sync.
class DetailMetrics {
  final List<HealthSample> series;
  final List<HeartRateSample> heartRate;
  final List<TempSample> temperature;
  const DetailMetrics({
    this.series = const [],
    this.heartRate = const [],
    this.temperature = const [],
  });

  List<HealthSample> seriesFor(String dayKey, String metric) =>
      series.where((s) => s.dayKey == dayKey && s.metric == metric).toList();

  List<HeartRateSample> heartRateFor(String dayKey) =>
      heartRate.where((h) => h.dayKey == dayKey).toList()
        ..sort((a, b) => a.sampledAt.compareTo(b.sampledAt));

  List<TempSample> tempFor(String dayKey) =>
      temperature.where((t) => t.dayKey == dayKey).toList();
}

final detailMetricsProvider = FutureProvider<DetailMetrics>((ref) async {
  ref.keepAlive();
  final configured = await ref.read(apiConfiguredProvider.future);
  if (!configured) return const DetailMetrics();
  final client = ref.read(metricsApiClientProvider);
  final (series, heartRate, temperature) = await (
    _orEmpty(client.fetchSeries(), 'series'),
    _orEmpty(client.fetchHeartRate(), 'heartRate'),
    _orEmpty(client.fetchTemperature(), 'temperature'),
  ).wait;
  return DetailMetrics(
    series: series,
    heartRate: heartRate,
    temperature: temperature,
  );
});

Future<List<T>> _orEmpty<T>(Future<List<T>> future, String label) async {
  try {
    return await future;
  } catch (e) {
    AppLogger.instance.log('$label: ${friendlyError(e)}', tag: 'metrics');
    return <T>[];
  }
}

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
    final configured = await ref.read(apiConfiguredProvider.future);
    if (!configured) return null;

    final client = ref.read(metricsApiClientProvider);
    // Home/Sleep/Activity only need daily aggregates. The heavy per-minute
    // datasets (series, heart rate, temperature) load lazily via
    // detailMetricsProvider when a detail/monitor screen is opened.
    final (
      days,
      sleep,
      workouts,
      activitySessions,
      coverage,
    ) = await (
      client.fetchDays(),
      _optional(client.fetchSleep(), 'sleep'),
      _optional(client.fetchWorkouts(), 'workouts'),
      _optional(client.fetchActivitySessions(), 'activitySessions'),
      _optionalCoverage(client.fetchCoverage()),
    ).wait;

    final store = await ref.read(sessionStoreProvider.future);
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
    // Fallback: read last-known battery from secure storage (persisted on sync)
    if (battery == null) {
      final auth = AuthKeyStorage(store: ref.read(authKeyStoreProvider));
      battery = await auth.readBattery();
    }
    return CloudMetricsSnapshot(
      days: days,
      sleep: sleep,
      workouts: workouts,
      activitySessions: activitySessions,
      lastSyncedAt: syncedAt,
      batteryPercent: battery,
      coverage: coverage,
    );
  }

  Future<List<T>> _optional<T>(Future<List<T>> future, String label) async {
    try {
      return await future;
    } catch (e) {
      AppLogger.instance.log('$label: ${friendlyError(e)}', tag: 'metrics');
      return [];
    }
  }

  Future<SyncCoverage?> _optionalCoverage(Future<SyncCoverage> future) async {
    try {
      return await future;
    } catch (e) {
      AppLogger.instance.log('coverage: ${friendlyError(e)}', tag: 'metrics');
      return null;
    }
  }

  Future<void> reload() async {
    final prev = state;
    state = const AsyncLoading<CloudMetricsSnapshot?>().copyWithPrevious(prev);
    state = await AsyncValue.guard(_load);
  }
}
