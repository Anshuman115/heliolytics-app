import 'package:dio/dio.dart';

import 'package:heliolytics/models/activity_metric.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/models/sleep_stage.dart';
import 'package:heliolytics/models/sync_coverage.dart';
import 'package:heliolytics/models/temp_sample.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/network/api_endpoint_policy.dart';
import 'package:heliolytics/services/network/metrics_api_transport.dart';
import 'package:heliolytics/services/network/request_signer.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/utils/ist_time.dart';

/// Client for the C3 read routes. Every request is signed per C5.
class MetricsApiClient {
  MetricsApiClient(
    ApiConfigStorage config, {
    required Dio dio,
    ApiEndpointPolicy? policy,
    RequestSigner? signer,
  }) : _transport = MetricsApiTransport(
         config,
         dio: dio,
         policy: policy,
         signer: signer,
       );

  static const int maxSummaryDays = 366;
  static const int maxSampleDays = 31;

  /// Compact sample series the API still serves.
  static const List<String> seriesMetrics = ['hrv', 'stress', 'resp', 'spo2'];

  final MetricsApiTransport _transport;

  Future<List<DayMetric>> fetchDays({int? windowDays}) async {
    const path = '/api/daily-metrics';
    final data = await _transport.getJsonObject(
      path,
      query: windowDays == null ? null : _summaryRange(path, windowDays),
    );
    return _dayList(data, path);
  }

  Future<List<DayMetric>> fetchDaysBetween({
    required String from,
    required String to,
  }) async {
    const path = '/api/daily-metrics';
    _checkRange(path, from: from, to: to, cap: maxSummaryDays);
    final data = await _transport.getJsonObject(
      path,
      query: {'from': from, 'to': to},
    );
    return _dayList(data, path);
  }

  Future<SleepDay?> fetchSleepForDay(String dayKey) async {
    const path = '/api/sleep';
    final data = await _transport.getJsonObject(path, query: _dayQuery(dayKey));
    final days = _list(data, 'days', path);
    if (days.isEmpty) return null;
    return SleepDay.fromJson(Map<String, dynamic>.from(days.first as Map));
  }

  Future<List<ActivityMetric>> fetchActivities({int? windowDays}) async {
    const path = '/api/activities';
    final data = await _transport.getJsonObject(
      path,
      query: windowDays == null ? null : _summaryRange(path, windowDays),
    );
    return _activityList(data, path);
  }

  Future<List<ActivityMetric>> fetchActivitiesForDay(String dayKey) async {
    const path = '/api/activities';
    final data = await _transport.getJsonObject(path, query: _dayQuery(dayKey));
    return _activityList(data, path);
  }

  Future<List<HealthSample>> fetchSeries({int? windowDays}) async {
    const path = '/api/metrics/series';
    final data = await _transport.getJsonObject(
      path,
      query: windowDays == null ? null : _sampleRange(path, windowDays),
    );
    return _parseSeries(path, data);
  }

  Future<List<HealthSample>> fetchSeriesForDay(String dayKey) async {
    const path = '/api/metrics/series';
    final data = await _transport.getJsonObject(path, query: _dayQuery(dayKey));
    return _parseSeries(path, data);
  }

  Future<List<HeartRateSample>> fetchHeartRate({int? windowDays}) async {
    const path = '/api/metrics/hr';
    final data = await _transport.getJsonObject(
      path,
      query: windowDays == null ? null : _sampleRange(path, windowDays),
    );
    return _parseHeartRate(path, data);
  }

  Future<List<HeartRateSample>> fetchHeartRateForDay(String dayKey) async {
    const path = '/api/metrics/hr';
    final data = await _transport.getJsonObject(path, query: _dayQuery(dayKey));
    return _parseHeartRate(path, data);
  }

  Future<List<TempSample>> fetchTemperature({int? windowDays}) async {
    const path = '/api/metrics/temperature';
    final data = await _transport.getJsonObject(
      path,
      query: windowDays == null ? null : _sampleRange(path, windowDays),
    );
    return _parseTemperature(path, data);
  }

  Future<List<TempSample>> fetchTemperatureForDay(String dayKey) async {
    const path = '/api/metrics/temperature';
    final data = await _transport.getJsonObject(path, query: _dayQuery(dayKey));
    return _parseTemperature(path, data);
  }

  Future<SyncCoverage> fetchCoverage() async {
    final data = await _transport.getJsonObject('/api/metrics/coverage');
    return SyncCoverage.fromJson(data);
  }

  Future<bool> testConnection() async {
    await _transport.getJsonObject(
      '/api/daily-metrics',
      query: _summaryRange('/api/daily-metrics', 1),
    );
    return true;
  }

  /// Loads exactly the three endpoints the selected day needs.
  Future<DayBundle> fetchDayBundle(String dayKey) async {
    final responses = await Future.wait<Map<String, dynamic>>([
      _transport.getJsonObject('/api/daily-metrics', query: _dayQuery(dayKey)),
      _transport.getJsonObject('/api/sleep', query: _dayQuery(dayKey)),
      _transport.getJsonObject('/api/activities', query: _dayQuery(dayKey)),
    ], eagerError: true);

    final days = _dayList(responses[0], '/api/daily-metrics');
    final sleepDays = _list(responses[1], 'days', '/api/sleep');
    final activities = _activityList(responses[2], '/api/activities');

    return DayBundle(
      day: days.isEmpty ? null : days.first,
      sleep: sleepDays.isEmpty
          ? null
          : SleepDay.fromJson(
              Map<String, dynamic>.from(sleepDays.first as Map),
            ),
      activities: activities,
    );
  }

  List<HealthSample> _parseSeries(String path, Map<String, dynamic> data) {
    final list = _list(data, 'days', path);
    final samples = <HealthSample>[];
    for (final dayObj in list) {
      final map = Map<String, dynamic>.from(dayObj as Map);
      final metric = map['metric'];
      if (metric is! String || !seriesMetrics.contains(metric)) {
        throw MetricsApiException.malformed(
          path: path,
          cause: FormatException('Unknown series metric: $metric'),
        );
      }
      final dayKey = _requireString(map, 'dayKey', path);
      final startTime = _requireTime(map, 'startTime', path);
      final compact = _compact(map, path);
      for (var i = 0; i < compact.offsets.length; i++) {
        samples.add(
          HealthSample(
            metric: metric,
            dayKey: dayKey,
            sampledAt: startTime.add(Duration(seconds: compact.offsets[i])),
            value: compact.values[i].toDouble(),
          ),
        );
      }
    }
    return samples;
  }

  List<HeartRateSample> _parseHeartRate(
    String path,
    Map<String, dynamic> data,
  ) {
    final list = _list(data, 'days', path);
    final samples = <HeartRateSample>[];
    for (final dayObj in list) {
      final map = Map<String, dynamic>.from(dayObj as Map);
      final dayKey = _requireString(map, 'dayKey', path);
      final startTime = _requireTime(map, 'startTime', path);
      final compact = _compact(map, path);
      for (var i = 0; i < compact.offsets.length; i++) {
        samples.add(
          HeartRateSample(
            dayKey: dayKey,
            sampledAt: startTime.add(Duration(seconds: compact.offsets[i])),
            bpm: compact.values[i].toInt(),
          ),
        );
      }
    }
    return samples;
  }

  List<TempSample> _parseTemperature(String path, Map<String, dynamic> data) {
    final list = _list(data, 'days', path);
    final samples = <TempSample>[];
    for (final dayObj in list) {
      final map = Map<String, dynamic>.from(dayObj as Map);
      final dayKey = _requireString(map, 'dayKey', path);
      final startTime = _requireTime(map, 'startTime', path);
      final compact = _compact(map, path);
      for (var i = 0; i < compact.offsets.length; i++) {
        samples.add(
          TempSample(
            dayKey: dayKey,
            sampledAt: startTime.add(Duration(seconds: compact.offsets[i])),
            celsius: compact.values[i].toDouble(),
          ),
        );
      }
    }
    return samples;
  }

  ({List<int> offsets, List<num> values}) _compact(
    Map<String, dynamic> map,
    String path,
  ) {
    final rawOffsets = map['offsets'];
    final rawValues = map['values'];
    if (rawOffsets is! List || rawValues is! List) {
      throw MetricsApiException.malformed(
        path: path,
        cause: const FormatException('Compact sample arrays are missing'),
      );
    }
    if (rawOffsets.length != rawValues.length) {
      throw MetricsApiException.malformed(
        path: path,
        cause: const FormatException('Offset and value counts differ'),
      );
    }
    final offsets = <int>[];
    final values = <num>[];
    for (var i = 0; i < rawOffsets.length; i++) {
      final offset = rawOffsets[i];
      final value = rawValues[i];
      if (offset is! num || value is! num) {
        throw MetricsApiException.malformed(
          path: path,
          cause: const FormatException('Compact sample entry is not numeric'),
        );
      }
      offsets.add(offset.toInt());
      values.add(value);
    }
    return (offsets: offsets, values: values);
  }

  String _requireString(Map<String, dynamic> map, String key, String path) {
    final value = map[key];
    if (value is! String) {
      throw MetricsApiException.malformed(
        path: path,
        cause: FormatException('Expected "$key" to be a string'),
      );
    }
    return value;
  }

  DateTime _requireTime(Map<String, dynamic> map, String key, String path) {
    final raw = _requireString(map, key, path);
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw MetricsApiException.malformed(
        path: path,
        cause: FormatException('Expected "$key" to be a timestamp'),
      );
    }
    return parsed.toLocal();
  }

  Map<String, String> _dayQuery(String dayKey) => {
    'from': dayKey,
    'to': dayKey,
  };

  Map<String, String> _summaryRange(String path, int days) =>
      _range(path, days, maxSummaryDays);

  Map<String, String> _sampleRange(String path, int days) =>
      _range(path, days, maxSampleDays);

  Map<String, String> _range(String path, int days, int cap) {
    if (days < 1) {
      throw MetricsApiException.malformed(
        path: path,
        cause: FormatException('Requested $days days'),
      );
    }
    if (days > cap) {
      throw MetricsApiException.malformed(
        path: path,
        cause: FormatException('Requested $days days, the cap is $cap'),
      );
    }
    final to = istToday();
    final from = istDaysAgo(days - 1);
    return {'from': dayKeyFor(from), 'to': dayKeyFor(to)};
  }

  void _checkRange(
    String path, {
    required String from,
    required String to,
    required int cap,
  }) {
    final start = DateTime.tryParse(from);
    final end = DateTime.tryParse(to);
    if (start == null || end == null || end.isBefore(start)) {
      throw MetricsApiException.malformed(
        path: path,
        cause: const FormatException('Invalid date range'),
      );
    }
    if (end.difference(start).inDays + 1 > cap) {
      throw MetricsApiException.malformed(
        path: path,
        cause: FormatException('Range exceeds $cap days'),
      );
    }
  }

  List<DayMetric> _dayList(Map<String, dynamic> data, String path) {
    final list = _list(data, 'days', path);
    return list
        .map((e) => DayMetric.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<ActivityMetric> _activityList(Map<String, dynamic> data, String path) {
    final list = _list(data, 'activities', path);
    return list
        .map(
          (e) => ActivityMetric.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  List<dynamic> _list(Map<String, dynamic> data, String key, String path) {
    final value = data[key];
    if (value is List) return List<dynamic>.from(value);
    throw MetricsApiException.malformed(
      path: path,
      cause: FormatException('Expected "$key" to be a JSON list'),
    );
  }
}
