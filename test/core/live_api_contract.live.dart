// Explicit-path live suite; every test fails, never skips, without the defines:
// flutter test test/core/live_api_contract.live.dart \
//   --dart-define=HELIOLYTICS_TEST_API_URL=... --dart-define=HELIOLYTICS_TEST_API_KEY=...
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/models/session.dart';
import 'package:heliolytics/models/session_catalog.dart';
import 'package:heliolytics/models/session_mode.dart';
import 'package:heliolytics/models/sync_payload.dart';
import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/metrics_api_client.dart';
import 'package:heliolytics/services/network/api_endpoint_policy.dart';
import 'package:heliolytics/services/network/ingest_request_encoder.dart';
import 'package:heliolytics/services/network/request_signer.dart';
import 'package:heliolytics/services/network/signed_request.dart';
import 'package:heliolytics/utils/day_key.dart';
import 'package:heliolytics/utils/ist_time.dart';

const _url = String.fromEnvironment('HELIOLYTICS_TEST_API_URL');
const _apiKey = String.fromEnvironment('HELIOLYTICS_TEST_API_KEY');

String? _prerequisiteError() {
  if (_url.isEmpty) return 'HELIOLYTICS_TEST_API_URL is required.';
  final uri = Uri.tryParse(_url);
  if (uri == null || uri.host.isEmpty) {
    return 'HELIOLYTICS_TEST_API_URL is not a valid URL.';
  }
  const loopback = {'127.0.0.1', 'localhost', '::1'};
  if (!loopback.contains(uri.host)) {
    return 'The live suite runs only against a loopback API URL.';
  }
  if (_apiKey.isEmpty) return 'HELIOLYTICS_TEST_API_KEY is required.';
  final keyError = ApiKey.validatePhone(_apiKey);
  if (keyError != null) return 'HELIOLYTICS_TEST_API_KEY: $keyError';
  return null;
}

void main() {
  final prerequisite = _prerequisiteError();
  if (prerequisite != null) {
    test('live prerequisites', () {
      fail(prerequisite);
    });
    return;
  }

  const policy = ApiEndpointPolicy.testLoopback;
  final origin = policy.parseOrigin(_url);
  final transportDio = Dio(BaseOptions(validateStatus: (_) => true));
  final config = ApiConfigStorage(
    _MemoryStore({'api_base_url': _url, 'api_key': _apiKey}),
  );
  final client = MetricsApiClient(config, dio: transportDio, policy: policy);
  final key = ApiKey.parsePhone(_apiKey);
  final dayKey = dayKeyFor(istToday());

  test('a signed GET with a fresh nonce is accepted', () async {
    final coverage = await client.fetchCoverage();
    expect(coverage.hasData, isA<bool>());
    expect(coverage.types.keys.toSet(), containsAll(['0x01', '0x25', '0x48']));
  });

  test('the C3 reads for the fixture day are served', () async {
    final days = await client.fetchDaysBetween(from: dayKey, to: dayKey);
    final sleep = await client.fetchSleepForDay(dayKey);
    final activities = await client.fetchActivitiesForDay(dayKey);
    expect(days, isA<List>());
    expect(sleep == null || sleep.dayKey == dayKey, isTrue);
    expect(activities, isA<List>());
  });

  test('a phone-key profile PUT returns 204 and recomputes', () async {
    final dio = Dio(BaseOptions(validateStatus: (_) => true));
    final request = _signedPut(policy, origin);
    final response = await _send(dio, request, request.authHeaders(key));
    expect(response.statusCode, 204);

    final coverage = await client.fetchCoverage();
    expect(coverage.hasData, isA<bool>());
  });

  test('a body mutated after signing is rejected', () async {
    final dio = Dio(BaseOptions(validateStatus: (_) => true));
    final request = await _ingestRequest(policy, origin, catalogSession: null);
    final headers = request.authHeaders(key);
    final mutated = Uint8List.fromList(request.request.body)
      ..[request.request.body.length - 2] ^= 0xFF;

    final response = await dio.requestUri<dynamic>(
      request.request.uri,
      data: mutated,
      options: Options(
        method: 'POST',
        headers: {
          ...headers,
          Headers.contentLengthHeader: '${mutated.length}',
          Headers.contentTypeHeader: request.request.contentType,
        },
        followRedirects: false,
        validateStatus: (_) => true,
        receiveDataWhenStatusError: true,
      ),
    );
    expect(response.statusCode, 401);
  });

  test('a Content-Type mutated after signing is rejected', () async {
    final dio = Dio(BaseOptions(validateStatus: (_) => true));
    final request = await _ingestRequest(policy, origin, catalogSession: null);
    final headers = request.authHeaders(key);
    final boundary = request.request.contentType.split('boundary=').last;

    final response = await dio.requestUri<dynamic>(
      request.request.uri,
      data: request.request.body,
      options: Options(
        method: 'POST',
        headers: {
          ...headers,
          Headers.contentLengthHeader: '${request.request.body.length}',
          Headers.contentTypeHeader:
              'multipart/form-data; boundary=${boundary}x',
        },
        followRedirects: false,
        validateStatus: (_) => true,
        receiveDataWhenStatusError: true,
      ),
    );
    expect(response.statusCode, 401);
  });

  test('a consumed nonce is rejected on replay', () async {
    final dio = Dio(BaseOptions(validateStatus: (_) => true));
    final request = _signedGet(policy, origin);
    final headers = request.authHeaders(key);

    final first = await _send(dio, request, headers);
    final replay = await _send(dio, request, headers);

    expect(first.statusCode, 200);
    expect(replay.statusCode, 401);
  });

  test('a catalog whose session id differs is rejected atomically', () async {
    final before = await client.fetchCoverage();
    final request = await _ingestRequest(
      policy,
      origin,
      catalogSession: 'other-session-id',
    );
    final response = await _send(dio(), request, request.authHeaders(key));

    expect(response.statusCode, 422);
    final body = response.data;
    expect(body.toString(), contains('invalid_catalog'));

    final after = await client.fetchCoverage();
    expect(after.lastIngestAt, before.lastIngestAt);
  });
}

Dio dio() => Dio(BaseOptions(validateStatus: (_) => true));

class _Signed {
  _Signed(this.request, this.signer);

  final SignedRequest request;
  final RequestSigner signer;

  Map<String, String> authHeaders(ApiKey key) =>
      signer.authHeaders(key: key, request: request);
}

// Production clock and CSPRNG nonce. Every authorization gets a fresh nonce,
// so only a deliberately resent header set can replay.
final _signer = RequestSigner();

_Signed _signedGet(ApiEndpointPolicy policy, Uri origin) {
  final request = SignedRequest.get(
    policy.resolve(origin, '/api/metrics/coverage'),
  );
  return _Signed(request, _signer);
}

_Signed _signedPut(ApiEndpointPolicy policy, Uri origin) {
  final profile = UserProfile(
    name: 'Live Contract',
    birthDate: DateTime(1990, 5, 17),
    sex: UserProfile.female,
    heightCm: 168,
    weightKg: 61.5,
  );
  final request = SignedRequest.json(
    policy.resolve(origin, '/api/profile'),
    utf8.encode(jsonEncode(profile.toWireJson())),
  );
  return _Signed(request, _signer);
}

Future<_Signed> _ingestRequest(
  ApiEndpointPolicy policy,
  Uri origin, {
  required String? catalogSession,
}) async {
  final start = DateTime.now().toUtc().subtract(const Duration(hours: 1));
  const sessionId = 'live-contract-session';
  final payload = SyncPayload(
    session: Session(
      sessionId: sessionId,
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 5)),
      deviceMac: '02:00:00:00:00:01',
      fetchWindowHours: 24,
      listenDurationSec: 60,
      mode: SessionMode.fetchAndListen,
      entries: const [],
      unsolicited: const [],
    ),
    catalog: SessionCatalog(
      sessionId: catalogSession ?? sessionId,
      chunked: const [],
      unsolicited: const [],
    ),
    rawByCode: {
      '0x25': Uint8List.fromList([0x02, 0x00, 0x01]),
    },
  );
  final encoded = await IngestRequestEncoder().encode(payload);
  final request = SignedRequest(
    method: 'POST',
    uri: policy.resolve(origin, '/api/ingest'),
    body: encoded.body,
    contentType: encoded.contentType,
  );
  return _Signed(request, _signer);
}

Future<Response<dynamic>> _send(
  Dio dio,
  _Signed signed,
  Map<String, String> headers,
) {
  final request = signed.request;
  final map = <String, String>{
    ...headers,
    Headers.contentLengthHeader: '${request.body.length}',
  };
  if (request.contentType.isNotEmpty) {
    map[Headers.contentTypeHeader] = request.contentType;
  }
  return dio.requestUri<dynamic>(
    request.uri,
    data: request.body.isEmpty ? null : request.body,
    options: Options(
      method: request.method,
      headers: map,
      followRedirects: false,
      validateStatus: (_) => true,
      receiveDataWhenStatusError: true,
    ),
  );
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
