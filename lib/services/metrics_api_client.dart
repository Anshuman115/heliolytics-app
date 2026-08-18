import 'package:dio/dio.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/daily_health_scores.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/models/sync_coverage.dart';
import 'package:heliolytics/models/temp_sample.dart';
import 'package:heliolytics/services/network/metrics_api_transport.dart';

class MetricsApiClient {
  MetricsApiClient(
    ApiConfigStorage config, {
    required Dio dio,
    MetricsApiTokenFactory? tokenFactory,
  }) : _transport = MetricsApiTransport(
         config,
         dio: dio,
         tokenFactory: tokenFactory,
       );

  final MetricsApiTransport _transport;

  Future<List<DayMetric>> fetchDays({int? windowDays}) async {
    const path = '/api/v1/daily-metrics';
    final data = await _get(path, windowDays);
    return _dayList(data, path);
  }

  Future<List<DayMetric>> fetchDaysBetween({
    required String from,
    required String to,
  }) async {
    const path = '/api/v1/daily-metrics';
    final data = await _transport.getJsonObject(
      path,
      queryParameters: {'from': from, 'to': to},
    );
    return _dayList(data, path);
  }

  Future<List<SleepMetric>> fetchSleep({int? windowDays}) async {
    const path = '/api/v1/sleep';
    final data = await _get(path, windowDays);
    final list = _list(data, 'sleep', path);
    return list
        .map((e) => SleepMetric.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<HealthSample>> fetchSeries({int? windowDays}) async {
    final data = await _get('/api/v1/metrics/series', windowDays);
    return _parseSeries(data);
  }

  Future<List<HealthSample>> fetchSeriesForDay(String dayKey) async {
    return _parseSeries(await _getForDay('/api/v1/metrics/series', dayKey));
  }

  List<HealthSample> _parseSeries(Map<String, dynamic> data) {
    const path = '/api/v1/metrics/series';
    final list = _list(data, 'days', path);
    final samples = <HealthSample>[];
    for (final dayObj in list) {
      final map = Map<String, dynamic>.from(dayObj as Map);
      final metric = map['metric'] as String;
      final dayKey = map['dayKey'] as String;
      final startTime = DateTime.parse(map['startTime'] as String).toLocal();
      final offsets = List<dynamic>.from(map['offsets'] as List? ?? []);
      final values = List<dynamic>.from(map['values'] as List? ?? []);
      for (var i = 0; i < offsets.length; i++) {
        final sampledAt = startTime.add(
          Duration(seconds: (offsets[i] as num).toInt()),
        );
        final val = (values[i] as num).toDouble();
        samples.add(
          HealthSample(
            metric: metric,
            dayKey: dayKey,
            sampledAt: sampledAt,
            value: val,
          ),
        );
      }
    }
    return samples;
  }

  Future<List<HeartRateSample>> fetchHeartRate({int? windowDays}) async {
    final data = await _get('/api/v1/metrics/hr', windowDays);
    return _parseHeartRate(data);
  }

  Future<List<HeartRateSample>> fetchHeartRateForDay(String dayKey) async {
    return _parseHeartRate(await _getForDay('/api/v1/metrics/hr', dayKey));
  }

  List<HeartRateSample> _parseHeartRate(Map<String, dynamic> data) {
    const path = '/api/v1/metrics/hr';
    final list = _list(data, 'days', path);
    final samples = <HeartRateSample>[];
    for (final dayObj in list) {
      final map = Map<String, dynamic>.from(dayObj as Map);
      final dayKey = map['dayKey'] as String;
      final startTime = DateTime.parse(map['startTime'] as String).toLocal();
      final offsets = List<dynamic>.from(map['offsets'] as List? ?? []);
      final values = List<dynamic>.from(map['values'] as List? ?? []);
      for (var i = 0; i < offsets.length; i++) {
        final sampledAt = startTime.add(
          Duration(seconds: (offsets[i] as num).toInt()),
        );
        final bpm = (values[i] as num).toInt();
        samples.add(
          HeartRateSample(dayKey: dayKey, sampledAt: sampledAt, bpm: bpm),
        );
      }
    }
    return samples;
  }

  Future<List<TempSample>> fetchTemperature({int? windowDays}) async {
    final data = await _get('/api/v1/metrics/temperature', windowDays);
    return _parseTemperature(data);
  }

  Future<List<TempSample>> fetchTemperatureForDay(String dayKey) async {
    return _parseTemperature(
      await _getForDay('/api/v1/metrics/temperature', dayKey),
    );
  }

  List<TempSample> _parseTemperature(Map<String, dynamic> data) {
    const path = '/api/v1/metrics/temperature';
    final list = _list(data, 'days', path);
    final samples = <TempSample>[];
    for (final dayObj in list) {
      final map = Map<String, dynamic>.from(dayObj as Map);
      final dayKey = map['dayKey'] as String;
      final startTime = DateTime.parse(map['startTime'] as String).toLocal();
      final offsets = List<dynamic>.from(map['offsets'] as List? ?? []);
      final values = List<dynamic>.from(map['values'] as List? ?? []);
      for (var i = 0; i < offsets.length; i++) {
        final sampledAt = startTime.add(
          Duration(seconds: (offsets[i] as num).toInt()),
        );
        final celsius = (values[i] as num).toDouble();
        samples.add(
          TempSample(dayKey: dayKey, sampledAt: sampledAt, celsius: celsius),
        );
      }
    }
    return samples;
  }

  Future<List<WorkoutMetric>> fetchWorkouts({int? windowDays}) async {
    const path = '/api/v1/metrics/workouts';
    final data = await _get(path, windowDays ?? devWorkoutFetchDays);
    final list = _list(data, 'workouts', path);
    return list
        .map((e) => WorkoutMetric.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<SyncCoverage> fetchCoverage() async {
    final data = await _getPlain('/api/v1/metrics/coverage');
    return SyncCoverage.fromJson(data);
  }

  Future<List<ActivitySessionMetric>> fetchActivitySessions({
    int? windowDays,
  }) async {
    const path = '/api/v1/metrics/activity-sessions';
    final data = await _get(path, windowDays ?? devActivitySessionFetchDays);
    final list = _list(data, 'activitySessions', path);
    return list
        .map(
          (e) => ActivitySessionMetric.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<bool> testConnection() async {
    await _get('/api/v1/daily-metrics', 1);
    return true;
  }

  Future<Map<String, dynamic>> _get(String path, int? windowDays) async {
    final days = windowDays ?? devFetchWindowDays;
    return _transport.getJsonObject(path, queryParameters: _range(days));
  }

  Future<Map<String, dynamic>> _getForDay(String path, String dayKey) async {
    return _transport.getJsonObject(
      path,
      queryParameters: {'from': dayKey, 'to': dayKey},
    );
  }

  Future<DayBundle> fetchDayBundle(String dayKey) async {
    final responses = await Future.wait<Map<String, dynamic>>([
      _getForDay('/api/v1/daily-metrics', dayKey),
      _getOptionalForDay('/api/v1/sleep', 'sleep', dayKey),
      _getOptionalForDay('/api/v1/metrics/workouts', 'workouts', dayKey),
      _getOptionalForDay(
        '/api/v1/metrics/activity-sessions',
        'activitySessions',
        dayKey,
      ),
    ], eagerError: true);
    final daysData = responses[0];
    final sleepData = responses[1];
    final workoutsData = responses[2];
    final sessionsData = responses[3];

    final days = _dayList(daysData, '/api/v1/daily-metrics');
    final day = days.isNotEmpty
        ? days.first
        : DayMetric(dayKey: dayKey, steps: 0);

    final sleepList = _list(sleepData, 'sleep', '/api/v1/sleep')
        .map((e) => SleepMetric.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final workouts = _list(workoutsData, 'workouts', '/api/v1/metrics/workouts')
        .map((e) => WorkoutMetric.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final sessions =
        _list(
              sessionsData,
              'activitySessions',
              '/api/v1/metrics/activity-sessions',
            )
            .map(
              (e) => ActivitySessionMetric.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();

    return DayBundle(
      day: day,
      sleep: sleepList,
      workouts: workouts,
      activitySessions: sessions,
    );
  }

  Future<Map<String, dynamic>> _getOptionalForDay(
    String path,
    String listKey,
    String dayKey,
  ) async {
    try {
      final data = await _getForDay(path, dayKey);
      _list(data, listKey, path);
      return data;
    } on MetricsApiException catch (error) {
      if (error.type == MetricsApiFailureType.notFound) {
        return {listKey: <dynamic>[]};
      }
      rethrow;
    }
  }

  Future<DailyHealthScores> fetchDailyHealthScores(String dayKey) async {
    const path = '/api/v1/daily-health-scores';
    final data = await _getForDay(path, dayKey);
    // Response is {"days": [<one tile per day in range>]} — a range wrapper,
    // even though from=to=dayKey narrows it to at most one entry.
    final days = _list(data, 'days', path);
    if (days.isEmpty) return DailyHealthScores.empty(dayKey);
    return DailyHealthScores.fromJson(
      Map<String, dynamic>.from(days.first as Map),
    );
  }

  Future<Map<String, dynamic>> _getPlain(String path) async {
    return _transport.getJsonObject(path);
  }

  List<DayMetric> _dayList(Map<String, dynamic> data, String path) {
    final list = _list(data, 'days', path);
    return list
        .map((e) => DayMetric.fromJson(Map<String, dynamic>.from(e as Map)))
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

  Map<String, String> _range(int windowDays) {
    // Use local time so the date window matches the user's calendar day.
    // Using UTC here caused 1 AM IST (= previous day UTC) to miss "today".
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, now.day);
    final from = to.subtract(Duration(days: windowDays));
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {'from': fmt(from), 'to': fmt(to)};
  }
}
