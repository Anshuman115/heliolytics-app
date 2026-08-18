import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/models/temp_sample.dart';
import 'package:heliolytics/providers/cloud_sync_provider.dart';
import 'package:heliolytics/providers/detail_metrics_provider.dart';
import 'package:heliolytics/providers/metric_trend_provider.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/metrics_api_client.dart';

void main() {
  test('metric trend propagates request failures', () async {
    final expected = StateError('trend failed');
    final container = _container(_FailingTrendClient(expected));
    addTearDown(container.dispose);

    await expectLater(
      container.read(metricTrendProvider(7).future),
      throwsA(same(expected)),
    );
  });

  test('detail metrics propagate request failures', () async {
    final expected = StateError('series failed');
    final container = _container(_FailingDetailClient(expected));
    addTearDown(container.dispose);

    await expectLater(
      container.read(detailMetricsProvider('2026-08-01').future),
      throwsA(same(expected)),
    );
  });
}

ProviderContainer _container(MetricsApiClient client) => ProviderContainer(
  overrides: [
    apiConfiguredProvider.overrideWith((ref) async => true),
    metricsApiClientProvider.overrideWithValue(client),
  ],
);

class _FailingTrendClient extends _TestMetricsApiClient {
  _FailingTrendClient(this.error);

  final Object error;

  @override
  Future<List<DayMetric>> fetchDays({int? windowDays}) => Future.error(error);
}

class _FailingDetailClient extends _TestMetricsApiClient {
  _FailingDetailClient(this.error);

  final Object error;

  @override
  Future<List<HealthSample>> fetchSeriesForDay(String dayKey) =>
      Future.error(error);

  @override
  Future<List<HeartRateSample>> fetchHeartRateForDay(String dayKey) async =>
      const [];

  @override
  Future<List<TempSample>> fetchTemperatureForDay(String dayKey) async =>
      const [];
}

class _TestMetricsApiClient extends MetricsApiClient {
  _TestMetricsApiClient()
    : super(ApiConfigStorage(_EmptyAuthKeyStore()), dio: Dio());
}

class _EmptyAuthKeyStore implements AuthKeyStore {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}
