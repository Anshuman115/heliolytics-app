import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/network/api_dio.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/services/metrics_api_client.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/models/temp_sample.dart';

final metricsApiClientProvider = Provider<MetricsApiClient>((ref) {
  return MetricsApiClient(
    ref.watch(apiConfigStorageProvider),
    dio: ref.watch(apiDioProvider),
  );
});

/// Heavy per-minute datasets (series, continuous HR, temperature) used only by
/// detail/monitor screens. Loads lazily on first watch and is cached for the
/// session; invalidated on sync.
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

final detailMetricsProvider = FutureProvider.family<DetailMetrics, String>((
  ref,
  dayKey,
) async {
  ref.keepAlive();
  final configured = await ref.read(apiConfiguredProvider.future);
  if (!configured) return const DetailMetrics();
  final client = ref.read(metricsApiClientProvider);
  final results = await Future.wait<Object>([
    client.fetchSeriesForDay(dayKey),
    client.fetchHeartRateForDay(dayKey),
    client.fetchTemperatureForDay(dayKey),
  ], eagerError: true);
  return DetailMetrics(
    series: results[0] as List<HealthSample>,
    heartRate: results[1] as List<HeartRateSample>,
    temperature: results[2] as List<TempSample>,
  );
});
