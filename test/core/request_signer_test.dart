import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heliolytics/services/network/request_signer.dart';
import 'package:heliolytics/services/network/signed_request.dart';

Map<String, dynamic> _loadFixture() {
  final file = File('test/fixtures/signing.json');
  if (!file.existsSync()) {
    throw StateError('signing fixture is required: ${file.path}');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

SignedRequest _requestFor(Map<String, dynamic> vector) {
  final path = vector['escapedPath'] as String;
  final query = vector['rawQuery'] as String;
  final uri = Uri.parse(
    'https://example.test$path${query.isEmpty ? '' : '?$query'}',
  );
  return SignedRequest(
    method: vector['method'] as String,
    uri: uri,
    body: base64.decode(vector['bodyBase64'] as String),
    contentType: vector['contentType'] as String,
  );
}

void main() {
  final fixture = _loadFixture();
  final vectors = (fixture['vectors'] as List).cast<Map<String, dynamic>>();

  test('fixture carries every published vector', () {
    expect(vectors.map((v) => v['id']), [
      'phone-get-daily',
      'web-put-profile',
      'phone-post-multipart',
      'phone-post-binary',
      'web-get-repeated-query',
    ]);
  });

  for (final vector in vectors) {
    final id = vector['id'] as String;
    test('$id canonical text, body hash and MAC match exactly', () {
      final request = _requestFor(vector);
      expect(request.escapedPath, vector['escapedPath']);
      expect(request.rawQuery, vector['rawQuery']);
      expect(request.bodySha256Hex, vector['bodySha256']);

      final canonical = canonicalText(
        kid: vector['kid'] as String,
        ts: vector['ts'] as int,
        nonce: vector['nonce'] as String,
        method: vector['method'] as String,
        escapedPath: vector['escapedPath'] as String,
        rawQuery: vector['rawQuery'] as String,
        bodySha256Hex: request.bodySha256Hex,
        contentType: vector['contentType'] as String,
      );
      expect(canonical, vector['canonicalText']);

      final key = ApiKey.parse('${vector['kid']}.${vector['secretHex']}');
      final signer = RequestSigner(
        now: () => vector['ts'] as int,
        nonce: () => vector['nonce'] as String,
      );
      final headers = signer.authHeaders(key: key, request: request);
      expect(headers[RequestSigner.authHeaderName], vector['authHeader']);
      expect(headers[RequestSigner.contentShaHeaderName], vector['bodySha256']);
    });
  }

  test('reordering the query changes the signature', () {
    final vector = vectors.first;
    final key = ApiKey.parse('phone.${vector['secretHex']}');
    final canonical = canonicalText(
      kid: 'phone',
      ts: 1760000000,
      nonce: '00112233445566778899aabbccddeeff',
      method: 'GET',
      escapedPath: vector['escapedPath'] as String,
      rawQuery: 'to=2026-10-19&from=2026-10-01',
      bodySha256Hex:
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      contentType: '',
    );
    final signature = Hmac(
      sha256,
      key.secretBytes,
    ).convert(utf8.encode(canonical)).toString();
    expect(signature, isNot(vector['signature']));
  });

  group('API key parsing', () {
    const secret =
        '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';

    test('accepts a phone key and keeps the raw 32 key bytes', () {
      final key = ApiKey.parsePhone('phone.$secret');
      expect(key.kid, ApiKey.phoneKid);
      expect(key.secretBytes, hasLength(32));
      expect(key.secretBytes.first, 0x00);
      expect(key.secretBytes.last, 0x1f);
    });

    test('rejects the web kid for Settings', () {
      expect(ApiKey.validatePhone('web.$secret'), isNotNull);
      expect(
        () => ApiKey.parsePhone('web.$secret'),
        throwsA(isA<ApiKeyFormatException>()),
      );
    });

    test('rejects uppercase, short and malformed secrets', () {
      expect(ApiKey.validatePhone('phone.${secret.toUpperCase()}'), isNotNull);
      expect(ApiKey.validatePhone('phone.0011'), isNotNull);
      expect(ApiKey.validatePhone('phone'), isNotNull);
      expect(ApiKey.validatePhone('phone.$secret.extra'), isNotNull);
      expect(ApiKey.validatePhone('Phone.$secret'), isNotNull);
    });
  });
}
