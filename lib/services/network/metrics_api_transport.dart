import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/network/heliolytics_token.dart';

typedef MetricsApiTokenFactory = String Function(String secret);

enum MetricsApiFailureType {
  unauthorized,
  notFound,
  clientError,
  serverError,
  unexpectedStatus,
  malformedResponse,
}

class MetricsApiException implements Exception {
  const MetricsApiException({
    required this.type,
    required this.path,
    this.statusCode,
    this.cause,
  });

  factory MetricsApiException.forStatus({
    required String path,
    required int? statusCode,
  }) {
    final type = switch (statusCode) {
      401 => MetricsApiFailureType.unauthorized,
      404 => MetricsApiFailureType.notFound,
      final int status when status >= 400 && status < 500 =>
        MetricsApiFailureType.clientError,
      final int status when status >= 500 => MetricsApiFailureType.serverError,
      _ => MetricsApiFailureType.unexpectedStatus,
    };
    return MetricsApiException(type: type, path: path, statusCode: statusCode);
  }

  factory MetricsApiException.malformed({
    required String path,
    Object? cause,
  }) => MetricsApiException(
    type: MetricsApiFailureType.malformedResponse,
    path: path,
    cause: cause,
  );

  final MetricsApiFailureType type;
  final String path;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    final status = statusCode == null ? '' : ', status: $statusCode';
    return 'MetricsApiException(${type.name}, path: $path$status)';
  }
}

class MetricsApiTransport {
  MetricsApiTransport(
    this._config, {
    required Dio dio,
    MetricsApiTokenFactory? tokenFactory,
  }) : _dio = dio,
       _tokenFactory = tokenFactory ?? mintHeliolyticsToken;

  final ApiConfigStorage _config;
  final Dio _dio;
  final MetricsApiTokenFactory _tokenFactory;

  Future<Map<String, dynamic>> getJsonObject(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final response = await _send(path, queryParameters);
      if (response.statusCode == 401 && attempt == 0) continue;
      return _decodeJsonObject(path, response);
    }
    throw StateError('Unreachable metrics request state');
  }

  Future<Response<dynamic>> _send(
    String path,
    Map<String, dynamic>? queryParameters,
  ) async {
    try {
      return await _dio.get<dynamic>(
        '${await _base()}$path',
        queryParameters: queryParameters,
        options: Options(headers: await _headers()),
      );
    } on DioException catch (error) {
      final response = error.response;
      if (response == null) rethrow;
      return response;
    }
  }

  Map<String, dynamic> _decodeJsonObject(
    String path,
    Response<dynamic> response,
  ) {
    final statusCode = response.statusCode;
    if (statusCode == null || statusCode < 200 || statusCode >= 300) {
      throw MetricsApiException.forStatus(path: path, statusCode: statusCode);
    }

    try {
      final raw = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      if (raw is! Map) {
        throw const FormatException('Expected a JSON object');
      }
      return Map<String, dynamic>.from(raw);
    } catch (error) {
      throw MetricsApiException.malformed(path: path, cause: error);
    }
  }

  Future<String> _base() async {
    final base = await _config.readBaseUrl();
    if (base == null || base.isEmpty) {
      throw StateError('Set API URL and API key in Settings');
    }
    return base.replaceAll(RegExp(r'/+$'), '');
  }

  Future<Map<String, String>> _headers() async {
    final secret = await _config.readSigningSecret();
    if (secret == null || secret.isEmpty) {
      throw StateError('Set API URL and API key in Settings');
    }
    return {'X-Heliolytics-Token': _tokenFactory(secret)};
  }
}
