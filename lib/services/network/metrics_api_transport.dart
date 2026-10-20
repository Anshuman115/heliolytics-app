import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/network/api_endpoint_policy.dart';
import 'package:heliolytics/services/network/ingest_request_encoder.dart';
import 'package:heliolytics/services/network/request_signer.dart';
import 'package:heliolytics/services/network/signed_request.dart';

enum MetricsApiFailureType {
  notConfigured,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  clientError,
  rateLimited,
  serverBusy,
  serverError,
  redirect,
  unexpectedStatus,
  malformedResponse,
}

class MetricsApiException implements Exception {
  const MetricsApiException({
    required this.type,
    required this.path,
    this.statusCode,
    this.code,
    this.message,
    this.retryAfter,
    this.cause,
  });

  factory MetricsApiException.malformed({
    required String path,
    Object? cause,
  }) => MetricsApiException(
    type: MetricsApiFailureType.malformedResponse,
    path: path,
    cause: cause,
  );

  factory MetricsApiException.forResponse({
    required String path,
    required Response<dynamic> response,
  }) {
    final statusCode = response.statusCode;
    final type = switch (statusCode) {
      401 => MetricsApiFailureType.unauthorized,
      403 => MetricsApiFailureType.forbidden,
      404 => MetricsApiFailureType.notFound,
      409 => MetricsApiFailureType.conflict,
      429 => MetricsApiFailureType.rateLimited,
      503 => MetricsApiFailureType.serverBusy,
      final int status when status >= 300 && status < 400 =>
        MetricsApiFailureType.redirect,
      final int status when status >= 400 && status < 500 =>
        MetricsApiFailureType.clientError,
      final int status when status >= 500 => MetricsApiFailureType.serverError,
      _ => MetricsApiFailureType.unexpectedStatus,
    };
    final body = _errorBody(response.data);
    return MetricsApiException(
      type: type,
      path: path,
      statusCode: statusCode,
      code: body?.code,
      message: body?.message,
      retryAfter: response.headers.value('retry-after'),
    );
  }

  final MetricsApiFailureType type;
  final String path;
  final int? statusCode;

  /// Server error code such as `session_conflict`, never a raw body.
  final String? code;

  /// Safe server message for display.
  final String? message;
  final String? retryAfter;
  final Object? cause;

  @override
  String toString() {
    final status = statusCode == null ? '' : ', status: $statusCode';
    final codePart = code == null ? '' : ', code: $code';
    return 'MetricsApiException(${type.name}, path: $path$status$codePart)';
  }
}

class _ErrorBody {
  const _ErrorBody(this.code, this.message);

  final String? code;
  final String? message;
}

_ErrorBody? _errorBody(Object? data) {
  if (data == null) return null;
  Object? raw;
  try {
    raw = data is String ? jsonDecode(data) : data;
  } catch (_) {
    return null;
  }
  if (raw is! Map) return null;
  final error = raw['error'];
  if (error is! Map) return null;
  final code = error['code'];
  final message = error['message'];
  return _ErrorBody(
    code is String ? code : null,
    message is String ? message : null,
  );
}

/// Signs and sends every authenticated request through one code path.
class MetricsApiTransport {
  MetricsApiTransport(
    this._config, {
    required Dio dio,
    ApiEndpointPolicy? policy,
    RequestSigner? signer,
  }) : _dio = dio,
       _policy = policy ?? ApiEndpointPolicy.current,
       _signer = signer ?? RequestSigner();

  final ApiConfigStorage _config;
  final Dio _dio;
  final ApiEndpointPolicy _policy;
  final RequestSigner _signer;

  Future<Map<String, dynamic>> getJsonObject(
    String path, {
    Map<String, String>? query,
  }) async {
    final request = await buildGet(path, query: query);
    final response = await send(request, await requireApiKey());
    return decodeJsonObject(path, response);
  }

  Future<SignedRequest> buildGet(
    String path, {
    Map<String, String>? query,
  }) async {
    final origin = await requireOrigin();
    return SignedRequest.get(_policy.resolve(origin, path, query: query));
  }

  Future<SignedRequest> buildJsonPut(
    String path,
    Map<String, dynamic> body,
  ) async {
    final origin = await requireOrigin();
    return SignedRequest.json(
      _policy.resolve(origin, path),
      utf8.encode(jsonEncode(body)),
    );
  }

  Future<SignedRequest> buildMultipart(
    String path,
    EncodedIngestRequest encoded,
  ) async {
    final origin = await requireOrigin();
    return SignedRequest(
      method: 'POST',
      uri: _policy.resolve(origin, path),
      body: encoded.body,
      contentType: encoded.contentType,
    );
  }

  Future<Uri> requireOrigin() async {
    final base = await _config.readBaseUrl();
    if (base == null) {
      throw const MetricsApiException(
        type: MetricsApiFailureType.notConfigured,
        path: '',
        message: 'Set the API URL in Settings.',
      );
    }
    return _policy.parseOrigin(base);
  }

  Future<ApiKey> requireApiKey() async {
    final raw = await _config.readApiKey();
    if (raw == null) {
      throw const MetricsApiException(
        type: MetricsApiFailureType.notConfigured,
        path: '',
        message: 'Enter your phone API key in Settings.',
      );
    }
    return ApiKey.parse(raw);
  }

  /// Sends [request] with fresh authorization for its frozen bytes.
  Future<Response<dynamic>> send(SignedRequest request, ApiKey key) async {
    final headers = <String, String>{
      ..._signer.authHeaders(key: key, request: request),
      Headers.contentLengthHeader: '${request.body.length}',
    };
    if (request.contentType.isNotEmpty) {
      headers[Headers.contentTypeHeader] = request.contentType;
    }
    try {
      return await _dio.requestUri<dynamic>(
        request.uri,
        data: request.body.isEmpty ? null : request.body,
        options: Options(
          method: request.method,
          headers: headers,
          followRedirects: false,
          receiveDataWhenStatusError: true,
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
    } on DioException catch (error) {
      final response = error.response;
      if (response != null) return response;
      rethrow;
    }
  }

  void ensureSuccess(String path, Response<dynamic> response) {
    final status = response.statusCode;
    if (status != null && status >= 200 && status < 300) return;
    throw MetricsApiException.forResponse(path: path, response: response);
  }

  Map<String, dynamic> decodeJsonObject(
    String path,
    Response<dynamic> response,
  ) {
    ensureSuccess(path, response);
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

  /// Decodes the `{"error":{...}}` body the backend returns with failures.
  MetricsApiException errorFor(String path, Response<dynamic> response) =>
      MetricsApiException.forResponse(path: path, response: response);
}
