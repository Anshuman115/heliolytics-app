import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/metrics_api_client.dart';
import 'package:heliolytics/services/network/api_endpoint_policy.dart';
import 'package:heliolytics/services/network/metrics_api_transport.dart';
import 'package:heliolytics/services/network/request_signer.dart';

const _dayKey = '2026-08-01';
const _key =
    'phone.000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';

void main() {
  test('a selected-day bundle makes exactly three signed requests', () async {
    final adapter = _Adapter((options) => _bundleResponse(options));
    final client = _client(adapter);

    final bundle = await client.fetchDayBundle(_dayKey);

    expect(adapter.requests.map((r) => r.options.uri.path).toSet(), {
      '/api/v1/daily-metrics',
      '/api/v1/sleep',
      '/api/v1/activities',
    });
    expect(adapter.requests, hasLength(3));
    expect(
      adapter.requests.every(
        (r) => (r.options.headers[RequestSigner.authHeaderName] as String)
            .startsWith('v2.phone.'),
      ),
      isTrue,
    );
    expect(bundle.day!.steps, 4321);
    expect(bundle.day!.avgHr, 61.4);
    expect(bundle.day!.hrvRmssd, 52.7);
    expect(bundle.day!.stressAvg, 23.6);
    expect(bundle.day!.skinTempNightC, 32.12);
    expect(bundle.day!.steps, isNotNull);
    expect(bundle.mainSleep!.totalMins, 430);
    expect(bundle.naps.single.score, isNull);
    expect(bundle.activities.single.minHr, 58);
  });

  test('an empty days list is a valid no-data bundle', () async {
    final adapter = _Adapter(
      (options) => _json(
        options,
        200,
        options.uri.path == '/api/v1/activities'
            ? <String, dynamic>{'activities': <dynamic>[]}
            : <String, dynamic>{'days': <dynamic>[]},
      ),
    );
    final bundle = await _client(adapter).fetchDayBundle(_dayKey);
    expect(bundle.day, isNull);
    expect(bundle.sleep, isNull);
    expect(bundle.activities, isEmpty);
    expect(bundle.hasData, isFalse);
  });

  test('a null days value is a protocol error, not empty data', () async {
    final adapter = _Adapter((options) => _json(options, 200, {'days': null}));
    await expectLater(
      _client(adapter).fetchDayBundle(_dayKey),
      throwsA(
        isA<MetricsApiException>().having(
          (e) => e.type,
          'type',
          MetricsApiFailureType.malformedResponse,
        ),
      ),
    );
  });

  test('401 is reported once with no automatic retry', () async {
    final adapter = _Adapter(
      (options) => _json(options, 401, {
        'error': {'code': 'unauthorized', 'message': 'Unauthorized'},
      }),
    );
    await expectLater(
      _client(adapter).fetchDays(windowDays: 1),
      throwsA(
        isA<MetricsApiException>().having(
          (e) => e.type,
          'type',
          MetricsApiFailureType.unauthorized,
        ),
      ),
    );
    expect(adapter.requests, hasLength(1));
  });

  test('a malformed successful object propagates', () async {
    final adapter = _Adapter((options) => _json(options, 200, 'not-json'));
    await expectLater(
      _client(adapter).fetchDays(windowDays: 1),
      throwsA(
        isA<MetricsApiException>().having(
          (e) => e.type,
          'type',
          MetricsApiFailureType.malformedResponse,
        ),
      ),
    );
  });

  test('mismatched compact arrays are rejected before indexing', () async {
    final adapter = _Adapter(
      (options) => _json(options, 200, {
        'days': [
          {
            'dayKey': _dayKey,
            'startTime': '2026-08-01T00:00:00+05:30',
            'offsets': [0, 60],
            'values': [97],
          },
        ],
      }),
    );
    await expectLater(
      _client(adapter).fetchSeriesForDay(_dayKey),
      throwsA(
        isA<MetricsApiException>().having(
          (e) => e.type,
          'type',
          MetricsApiFailureType.malformedResponse,
        ),
      ),
    );
  });

  test('the day range is one inclusive IST day', () async {
    final adapter = _Adapter(
      (options) => _json(options, 200, {'days': <dynamic>[]}),
    );
    await _client(adapter).fetchDaysBetween(from: _dayKey, to: _dayKey);
    expect(
      adapter.requests.single.options.uri.query,
      'from=$_dayKey&to=$_dayKey',
    );
  });

  test('a summary request above 366 days is refused locally', () async {
    final adapter = _Adapter(
      (options) => _json(options, 200, {'days': <dynamic>[]}),
    );
    await expectLater(
      _client(adapter).fetchDays(windowDays: 367),
      throwsA(isA<MetricsApiException>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test(
    'the default policy accepts a loopback http origin in development',
    () async {
      final store = _MemoryStore({'api_base_url': 'http://127.0.0.1:8080'});
      final transport = MetricsApiTransport(
        ApiConfigStorage(store),
        dio: Dio(BaseOptions(validateStatus: (_) => true)),
      );

      expect(ApiEndpointPolicy.current.allowInsecureLocal, isTrue);
      expect(
        (await transport.requireOrigin()).toString(),
        'http://127.0.0.1:8080',
      );
    },
  );

  test('the production policy refuses the same loopback origin', () async {
    final store = _MemoryStore({'api_base_url': 'http://127.0.0.1:8080'});
    final transport = MetricsApiTransport(
      ApiConfigStorage(store),
      dio: Dio(BaseOptions(validateStatus: (_) => true)),
      policy: ApiEndpointPolicy.production,
    );

    await expectLater(
      transport.requireOrigin(),
      throwsA(isA<ApiEndpointException>()),
    );
  });
}

ResponseBody _bundleResponse(RequestOptions options) {
  final path = options.uri.path;
  if (path == '/api/v1/daily-metrics') {
    return _json(options, 200, {
      'days': [
        {
          'dayKey': _dayKey,
          'steps': 4321,
          'avgHr': 61.4,
          'restingHr': 52.3,
          'hrvRmssd': 52.7,
          'respRate': 14.2,
          'spo2Avg': 97.1,
          'spo2Min': 95,
          'spo2SleepAvg': 96.4,
          'spo2SleepMin': 94,
          'spo2Samples': 12,
          'stressAvg': 23.6,
          'skinTempNightC': 32.12,
          'skinTempDeviationC': -0.21,
          'sleepScore': 82,
          'sleepMins': 430,
          'sleepDeepMins': 80,
          'sleepRemMins': 90,
          'sleepLightMins': 230,
          'sleepWakeMins': 30,
          'timeInBedMins': 460,
          'sleepEfficiencyPct': 93,
          'napCount': 1,
          'workoutCount': 1,
          'autoActivityCount': 1,
          'workoutCalories': 320,
          'trainingLoad': 41.7,
          'paiScore': 77,
          'readiness': 68,
          'readinessStatus': 'scored',
          'readinessBand': 'good',
          'readinessComponents': {
            'version': 1,
            'status': 'scored',
            'score': 68,
            'raw': 0.42,
            'baselineNights': 21,
            'components': [
              {
                'name': 'hrv',
                'value': 52.7,
                'x': 0.3,
                'center': 48.1,
                'sd': 4.2,
                'sdPersonal': 3.8,
                'n': 240,
                'z': 1.2,
                'sub': 62.0,
                'weight': 0.4,
                'points': 24.8,
                'nights': 21,
                'chronic': null,
                'ratio': null,
                'dev': null,
              },
            ],
            'flags': ['missing:resp_rate'],
          },
          'updatedAt': '2026-08-02T03:00:00Z',
        },
      ],
    });
  }
  if (path == '/api/v1/sleep') {
    return _json(options, 200, {
      'days': [
        {
          'dayKey': _dayKey,
          'main': {
            'startedAt': '2026-07-31T21:00:00Z',
            'endedAt': '2026-08-01T05:10:00Z',
            'score': 82,
            'totalMins': 430,
            'deepMins': 80,
            'remMins': 90,
            'lightMins': 230,
            'wakeMins': 30,
            'stagesTruncated': false,
            'stages': [
              {
                'start': '2026-07-31T21:00:00Z',
                'end': '2026-07-31T21:05:00Z',
                'type': 5,
              },
            ],
          },
          'naps': [
            {
              'startedAt': '2026-08-01T12:00:00Z',
              'endedAt': '2026-08-01T12:40:00Z',
              'score': null,
              'totalMins': 40,
              'deepMins': 0,
              'remMins': 10,
              'lightMins': 30,
              'wakeMins': 0,
              'stagesTruncated': false,
              'stages': <dynamic>[],
            },
          ],
        },
      ],
    });
  }
  if (path == '/api/v1/activities') {
    return _json(options, 200, {
      'activities': [
        {
          'kind': 'workout',
          'dayKey': _dayKey,
          'startedAt': '2026-08-01T06:00:00Z',
          'endedAt': '2026-08-01T06:45:00Z',
          'durationSec': 2700,
          'sportType': 1,
          'sportName': 'Outdoor Run',
          'calories': 320,
          'avgHr': 142,
          'maxHr': 171,
          'minHr': 58,
          'steps': 5400,
          'hasDetail': true,
        },
      ],
    });
  }
  return ResponseBody.fromString('', 404);
}

ResponseBody _json(RequestOptions options, int status, Object? body) =>
    ResponseBody.fromString(
      body is String ? body : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

MetricsApiClient _client(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(validateStatus: (_) => true));
  dio.httpClientAdapter = adapter;
  return MetricsApiClient(
    ApiConfigStorage(
      _MemoryStore({
        'api_base_url': 'https://example.test',
        'api_key_v2': _key,
      }),
    ),
    dio: dio,
    signer: RequestSigner(
      now: () => 1760000000,
      nonce: () => '00112233445566778899aabbccddeeff',
    ),
  );
}

typedef _Captured = ({RequestOptions options, Uint8List body});

class _Adapter implements HttpClientAdapter {
  _Adapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;
  final List<_Captured> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chunks = requestStream == null
        ? <Uint8List>[]
        : await requestStream.toList();
    requests.add((
      options: options,
      body: Uint8List.fromList([for (final chunk in chunks) ...chunk]),
    ));
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

class _MemoryStore implements AuthKeyStore {
  _MemoryStore(this.values);

  final Map<String, String> values;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
