import 'package:dio/dio.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/network/heliolytics_token.dart';
import 'package:heliolytics/models/day_bundle.dart';
import 'package:heliolytics/models/daily_health_scores.dart';
import 'package:heliolytics/models/day_metric.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/hr_sample.dart';
import 'package:heliolytics/models/sync_coverage.dart';
import 'package:heliolytics/models/temp_sample.dart';

class MetricsApiClient {
  final ApiConfigStorage _config;
  final Dio _dio;

  MetricsApiClient(this._config, {required Dio dio}) : _dio = dio;

  Future<List<DayMetric>> fetchDays({int? windowDays}) async {
    final data = await _get('/api/v1/metrics/days', windowDays);
    return _dayList(data['days']);
  }

  Future<List<SleepMetric>> fetchSleep({int? windowDays}) async {
    final data = await _get('/api/v1/metrics/sleep', windowDays);
    final list = data['sleep'] as List<dynamic>? ?? [];
    return list.map((e) => SleepMetric.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<HealthSample>> fetchSeries({int? windowDays}) async {
    final data = await _get('/api/v1/metrics/series', windowDays);
    final list = data['days'] as List<dynamic>? ?? [];
    final samples = <HealthSample>[];
    for (final dayObj in list) {
      final map = Map<String, dynamic>.from(dayObj as Map);
      final metric = map['metric'] as String;
      final dayKey = map['dayKey'] as String;
      final startTime = DateTime.parse(map['startTime'] as String).toLocal();
      final offsets = List<dynamic>.from(map['offsets'] as List? ?? []);
      final values = List<dynamic>.from(map['values'] as List? ?? []);
      for (var i = 0; i < offsets.length; i++) {
        final sampledAt = startTime.add(Duration(seconds: (offsets[i] as num).toInt()));
        final val = (values[i] as num).toDouble();
        samples.add(HealthSample(
          metric: metric,
          dayKey: dayKey,
          sampledAt: sampledAt,
          value: val,
        ));
      }
    }
    return samples;
  }

  Future<List<HeartRateSample>> fetchHeartRate({int? windowDays}) async {
    final data = await _get('/api/v1/metrics/hr', windowDays);
    final list = data['days'] as List<dynamic>? ?? [];
    final samples = <HeartRateSample>[];
    for (final dayObj in list) {
      final map = Map<String, dynamic>.from(dayObj as Map);
      final dayKey = map['dayKey'] as String;
      final startTime = DateTime.parse(map['startTime'] as String).toLocal();
      final offsets = List<dynamic>.from(map['offsets'] as List? ?? []);
      final values = List<dynamic>.from(map['values'] as List? ?? []);
      for (var i = 0; i < offsets.length; i++) {
        final sampledAt = startTime.add(Duration(seconds: (offsets[i] as num).toInt()));
        final bpm = (values[i] as num).toInt();
        samples.add(HeartRateSample(
          dayKey: dayKey,
          sampledAt: sampledAt,
          bpm: bpm,
        ));
      }
    }
    return samples;
  }

  Future<List<TempSample>> fetchTemperature({int? windowDays}) async {
    final data = await _get('/api/v1/metrics/temperature', windowDays);
    final list = data['days'] as List<dynamic>? ?? [];
    final samples = <TempSample>[];
    for (final dayObj in list) {
      final map = Map<String, dynamic>.from(dayObj as Map);
      final dayKey = map['dayKey'] as String;
      final startTime = DateTime.parse(map['startTime'] as String).toLocal();
      final offsets = List<dynamic>.from(map['offsets'] as List? ?? []);
      final values = List<dynamic>.from(map['values'] as List? ?? []);
      for (var i = 0; i < offsets.length; i++) {
        final sampledAt = startTime.add(Duration(seconds: (offsets[i] as num).toInt()));
        final celsius = (values[i] as num).toDouble();
        samples.add(TempSample(
          dayKey: dayKey,
          sampledAt: sampledAt,
          celsius: celsius,
        ));
      }
    }
    return samples;
  }

  Future<List<WorkoutMetric>> fetchWorkouts({int? windowDays}) async {
    final data = await _get(
      '/api/v1/metrics/workouts',
      windowDays ?? devWorkoutFetchDays,
    );
    final list = data['workouts'] as List<dynamic>? ?? [];
    return list.map((e) => WorkoutMetric.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<SyncCoverage> fetchCoverage() async {
    final data = await _getPlain('/api/v1/metrics/coverage');
    return SyncCoverage.fromJson(data);
  }

  Future<List<ActivitySessionMetric>> fetchActivitySessions({int? windowDays}) async {
    final data = await _get(
      '/api/v1/metrics/activity-sessions',
      windowDays ?? devActivitySessionFetchDays,
    );
    final list = data['activitySessions'] as List<dynamic>? ?? [];
    return list.map((e) => ActivitySessionMetric.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<bool> testConnection() async {
    await _get('/api/v1/metrics/days', 1);
    return true;
  }

  Future<Map<String, dynamic>> _get(String path, int? windowDays) async {
    final days = windowDays ?? devFetchWindowDays;
    final res = await _dio.get<Map<String, dynamic>>(
      '${await _base()}$path',
      queryParameters: _range(days),
      options: Options(headers: await _headers()),
    );
    if (res.statusCode == 401) {
      throw DioException.badResponse(
        statusCode: 401,
        requestOptions: res.requestOptions,
        response: res,
      );
    }
    if (res.statusCode == 404) {
      throw DioException.badResponse(
        statusCode: 404,
        requestOptions: res.requestOptions,
        response: res,
      );
    }
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> _getForDay(String path, String dayKey) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '${await _base()}$path',
      queryParameters: {'from': dayKey, 'to': dayKey},
      options: Options(headers: await _headers()),
    );
    if (res.statusCode == 401 || res.statusCode == 404) {
      throw DioException.badResponse(
        statusCode: res.statusCode!,
        requestOptions: res.requestOptions,
        response: res,
      );
    }
    return res.data ?? {};
  }

  Future<DayBundle> fetchDayBundle(String dayKey) async {
    final (daysData, sleepData, workoutsData, sessionsData) = await (
      _getForDay('/api/v1/metrics/days', dayKey),
      _getForDay('/api/v1/metrics/sleep', dayKey),
      _getForDay('/api/v1/metrics/workouts', dayKey),
      _getForDay('/api/v1/metrics/activity-sessions', dayKey),
    ).wait;

    final days = _dayList(daysData['days']);
    final day = days.isNotEmpty
        ? days.first
        : DayMetric(dayKey: dayKey, steps: 0);

    final sleepList = (sleepData['sleep'] as List<dynamic>? ?? [])
        .map((e) => SleepMetric.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final workouts = (workoutsData['workouts'] as List<dynamic>? ?? [])
        .map((e) => WorkoutMetric.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final sessions = (sessionsData['activitySessions'] as List<dynamic>? ?? [])
        .map((e) => ActivitySessionMetric.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return DayBundle(
      day: day,
      sleep: sleepList,
      workouts: workouts,
      activitySessions: sessions,
    );
  }

  Future<DailyHealthScores> fetchDailyHealthScores(String dayKey) async {
    final data = await _getForDay('/api/v1/daily-health-scores', dayKey);
    if (data.isEmpty) return DailyHealthScores.empty(dayKey);
    return DailyHealthScores.fromJson({...data, 'dayKey': dayKey});
  }

  Future<Map<String, dynamic>> _getPlain(String path) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '${await _base()}$path',
      options: Options(headers: await _headers()),
    );
    if (res.statusCode == 401) {
      throw DioException.badResponse(
        statusCode: 401,
        requestOptions: res.requestOptions,
        response: res,
      );
    }
    return res.data ?? {};
  }

  List<DayMetric> _dayList(dynamic raw) {
    final list = raw as List<dynamic>? ?? [];
    return list.map((e) => DayMetric.fromJson(Map<String, dynamic>.from(e as Map))).toList();
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

  Future<String> _base() async {
    final base = await _config.readBaseUrl();
    if (base == null || base.isEmpty) throw StateError('Set API URL and API key in Settings');
    return base.replaceAll(RegExp(r'/+$'), '');
  }

  Future<Map<String, String>> _headers() async {
    final secret = await _config.readSigningSecret();
    if (secret == null || secret.isEmpty) {
      throw StateError('Set API URL and API key in Settings');
    }
    return {'X-Heliolytics-Token': mintHeliolyticsToken(secret)};
  }
}
