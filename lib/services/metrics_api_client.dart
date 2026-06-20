import 'package:dio/dio.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/services/network/heliolytics_token.dart';
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
    final list = data['samples'] as List<dynamic>? ?? [];
    return list.map((e) => HealthSample.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<HeartRateSample>> fetchHeartRate({int? windowDays}) async {
    final data = await _get('/api/v1/metrics/hr', windowDays);
    final list = data['samples'] as List<dynamic>? ?? [];
    return list.map((e) => HeartRateSample.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<TempSample>> fetchTemperature({int? windowDays}) async {
    final data = await _get('/api/v1/metrics/temperature', windowDays);
    final list = data['samples'] as List<dynamic>? ?? [];
    return list.map((e) => TempSample.fromJson(Map<String, dynamic>.from(e as Map))).toList();
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
    final to = DateTime.now().toUtc();
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
