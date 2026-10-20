import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/models/user_profile.dart';
import 'package:heliolytics/services/ble/auth/auth_key_store.dart';
import 'package:heliolytics/services/config/api_config_storage.dart';
import 'package:heliolytics/services/network/metrics_api_transport.dart';
import 'package:heliolytics/services/network/profile_api_client.dart';
import 'package:heliolytics/services/network/request_signer.dart';

const _key =
    'phone.000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';

void main() {
  test('PUT sends one signed JSON body with every nullable key', () async {
    final adapter = _RecordingAdapter(
      (options, body) => ResponseBody.fromString('', 204),
    );
    final client = _client(adapter);
    const profile = UserProfile(
      name: null,
      birthDate: null,
      sex: null,
      heightCm: null,
      weightKg: null,
    );

    await client.submitProfile(profile);

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.options.method, 'PUT');
    expect(request.options.uri.path, '/api/profile');
    expect(
      request.options.headers[Headers.contentTypeHeader],
      'application/json',
    );
    expect(
      request.options.headers[RequestSigner.contentShaHeaderName],
      sha256.convert(request.body).toString(),
    );
    final auth =
        request.options.headers[RequestSigner.authHeaderName] as String;
    expect(auth, startsWith('phone.'));

    final decoded =
        jsonDecode(utf8.decode(request.body)) as Map<String, dynamic>;
    expect(decoded.keys.toSet(), {
      'name',
      'birthDate',
      'sex',
      'heightCm',
      'weightKg',
    });
    expect(decoded.values.every((v) => v == null), isTrue);
  });

  test('sends a date-only birth date and formula sex', () async {
    final adapter = _RecordingAdapter(
      (options, body) => ResponseBody.fromString('', 204),
    );
    final client = _client(adapter);

    await client.submitProfile(
      UserProfile(
        name: 'Ada',
        birthDate: DateTime(1995, 4, 12),
        sex: UserProfile.female,
        heightCm: 171.5,
        weightKg: 62,
      ),
    );

    final decoded =
        jsonDecode(utf8.decode(adapter.requests.single.body))
            as Map<String, dynamic>;
    expect(decoded['birthDate'], '1995-04-12');
    expect(decoded['sex'], 'female');
    expect(decoded['heightCm'], 171.5);
    expect(decoded['weightKg'], 62);
  });

  test('a non-204 outcome throws with the server code', () async {
    final adapter = _RecordingAdapter(
      (options, body) => ResponseBody.fromString(
        '{"error":{"code":"invalid_profile","message":"Birth date is invalid"}}',
        422,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      ),
    );
    final client = _client(adapter);

    await expectLater(
      client.submitProfile(const UserProfile()),
      throwsA(
        isA<MetricsApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.code, 'code', 'invalid_profile'),
      ),
    );
  });

  test('a redirect is not followed and is reported', () async {
    final adapter = _RecordingAdapter(
      (options, body) => ResponseBody.fromString('', 307),
    );
    final client = _client(adapter);

    await expectLater(
      client.submitProfile(const UserProfile()),
      throwsA(
        isA<MetricsApiException>().having(
          (e) => e.type,
          'type',
          MetricsApiFailureType.redirect,
        ),
      ),
    );
    expect(adapter.requests, hasLength(1));
  });
}

ProfileApiClient _client(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(validateStatus: (_) => true));
  dio.httpClientAdapter = adapter;
  final config = ApiConfigStorage(
    _MemoryStore({'api_base_url': 'https://example.test', 'api_key': _key}),
  );
  return ProfileApiClient(
    config,
    dio: dio,
    signer: RequestSigner(
      now: () => 1760000000,
      nonce: () => '00112233445566778899aabbccddeeff',
    ),
  );
}

typedef _Captured = ({RequestOptions options, Uint8List body});

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._respond);

  final ResponseBody Function(RequestOptions options, Uint8List body) _respond;
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
    final body = Uint8List.fromList([for (final chunk in chunks) ...chunk]);
    requests.add((options: options, body: body));
    return _respond(options, body);
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
