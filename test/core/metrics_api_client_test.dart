import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/metrics_api_client.dart';
import 'package:heliolytics/services/network/metrics_api_transport.dart';

void main() {
  const dayKey = '2026-08-01';

  group('MetricsApiClient HTTP reliability', () {
    test('retries a plain-text 401 once with a fresh token', () async {
      final stub = _StubInterceptor((options, attempt) {
        if (attempt == 1) return _response(options, 401, 'unauthorized\n');
        return _response(options, 200, {'days': <dynamic>[]});
      });
      var tokenNumber = 0;
      final client = _client(
        stub,
        tokenFactory: (_) => 'token-${++tokenNumber}',
      );

      expect(await client.fetchDays(windowDays: 1), isEmpty);
      expect(stub.requests, hasLength(2));
      expect(
        stub.requests.map(_token).toList(),
        equals(['token-1', 'token-2']),
      );
    });

    test('maps a repeated 401 after exactly two attempts', () async {
      final stub = _StubInterceptor(
        (options, _) => _response(options, 401, 'unauthorized\n'),
      );
      var tokenNumber = 0;
      final client = _client(
        stub,
        tokenFactory: (_) => 'token-${++tokenNumber}',
      );

      await expectLater(
        client.fetchDays(windowDays: 1),
        throwsA(
          isA<MetricsApiException>()
              .having(
                (error) => error.type,
                'type',
                MetricsApiFailureType.unauthorized,
              )
              .having((error) => error.statusCode, 'statusCode', 401),
        ),
      );
      expect(stub.requests, hasLength(2));
      expect(stub.requests.map(_token).toSet(), hasLength(2));
    });

    test('rejects a malformed successful payload', () async {
      final stub = _StubInterceptor(
        (options, _) => _response(options, 200, 'not-json'),
      );
      final client = _client(stub);

      await expectLater(
        client.fetchDays(windowDays: 1),
        throwsA(
          isA<MetricsApiException>().having(
            (error) => error.type,
            'type',
            MetricsApiFailureType.malformedResponse,
          ),
        ),
      );
    });

    test('decodes a JSON object delivered as text', () async {
      final stub = _StubInterceptor(
        (options, _) => _response(options, 200, '{"days":[]}'),
      );

      expect(await _client(stub).fetchDays(windowDays: 1), isEmpty);
    });

    test('maps an explicitly optional 404 to an empty list', () async {
      final stub = _bundleStub(
        dayKey,
        sleepResponse: (options, _) => _response(options, 404, 'not found\n'),
      );

      final bundle = await _client(stub).fetchDayBundle(dayKey);

      expect(bundle.day.steps, 1234);
      expect(bundle.sleep, isEmpty);
      expect(stub.attemptsFor('/api/v1/sleep'), 1);
    });

    test('does not turn an optional endpoint 401 into empty data', () async {
      final stub = _bundleStub(
        dayKey,
        sleepResponse: (options, _) =>
            _response(options, 401, 'unauthorized\n'),
      );

      await expectLater(
        _client(stub).fetchDayBundle(dayKey),
        throwsA(
          isA<MetricsApiException>().having(
            (error) => error.type,
            'type',
            MetricsApiFailureType.unauthorized,
          ),
        ),
      );
      expect(stub.attemptsFor('/api/v1/sleep'), 2);
    });

    test(
      'does not turn an optional endpoint timeout into empty data',
      () async {
        final stub = _bundleStub(
          dayKey,
          sleepResponse: (options, _) => DioException.receiveTimeout(
            timeout: const Duration(seconds: 1),
            requestOptions: options,
          ),
        );

        await expectLater(
          _client(stub).fetchDayBundle(dayKey),
          throwsA(
            isA<DioException>().having(
              (error) => error.type,
              'type',
              DioExceptionType.receiveTimeout,
            ),
          ),
        );
        expect(stub.attemptsFor('/api/v1/sleep'), 1);
      },
    );
  });
}

MetricsApiClient _client(
  _StubInterceptor stub, {
  MetricsApiTokenFactory? tokenFactory,
}) {
  final dio = Dio(BaseOptions(validateStatus: (_) => true));
  dio.interceptors.add(stub);
  final config = ApiConfigStorage(
    _MemoryAuthKeyStore({
      'api_base_url': 'https://example.test',
      'signing_secret': 'test-secret',
    }),
  );
  return MetricsApiClient(
    config,
    dio: dio,
    tokenFactory: tokenFactory ?? (_) => 'token',
  );
}

_StubInterceptor _bundleStub(
  String dayKey, {
  required _StubResult Function(RequestOptions, int) sleepResponse,
}) {
  return _StubInterceptor((options, attempt) {
    return switch (options.uri.path) {
      '/api/v1/daily-metrics' => _response(options, 200, {
        'days': [
          {'dayKey': dayKey, 'steps': 1234},
        ],
      }),
      '/api/v1/sleep' => sleepResponse(options, attempt),
      '/api/v1/metrics/workouts' => _response(options, 200, {
        'workouts': <dynamic>[],
      }),
      '/api/v1/metrics/activity-sessions' => _response(options, 200, {
        'activitySessions': <dynamic>[],
      }),
      _ => _response(options, 404, 'not found\n'),
    };
  });
}

String? _token(RequestOptions options) =>
    options.headers['X-Heliolytics-Token'] as String?;

Response<dynamic> _response(
  RequestOptions options,
  int statusCode,
  Object? data,
) => Response<dynamic>(
  requestOptions: options,
  statusCode: statusCode,
  data: data,
);

typedef _StubResult = Object;
typedef _StubResponder =
    _StubResult Function(RequestOptions options, int attempt);

class _StubInterceptor extends Interceptor {
  _StubInterceptor(this._respond);

  final _StubResponder _respond;
  final List<RequestOptions> requests = [];
  final Map<String, int> _attempts = {};

  int attemptsFor(String path) => _attempts[path] ?? 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    final path = options.uri.path;
    final attempt = (_attempts[path] ?? 0) + 1;
    _attempts[path] = attempt;
    final result = _respond(options, attempt);
    if (result is DioException) {
      handler.reject(result);
      return;
    }
    handler.resolve(result as Response<dynamic>);
  }
}

class _MemoryAuthKeyStore implements AuthKeyStore {
  _MemoryAuthKeyStore(this._values);

  final Map<String, String> _values;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}
