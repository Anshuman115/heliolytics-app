import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:heliolytics/services/network/signed_request.dart';

/// Raised when a Settings API key is not a usable `phone` credential.
class ApiKeyFormatException implements Exception {
  const ApiKeyFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Parsed `kid.secret` API key. Only the `phone` kid is accepted by the app.
class ApiKey {
  ApiKey._(this.kid, this.secretHex, this.secretBytes);

  static const String phoneKid = 'phone';

  static final RegExp _kidPattern = RegExp(r'^[a-z][a-z0-9-]{1,15}$');
  static final RegExp _secretPattern = RegExp(r'^[0-9a-f]{64}$');

  final String kid;
  final String secretHex;
  final Uint8List secretBytes;

  /// Parses the C5 `kid.secret` grammar without restricting the kid.
  factory ApiKey.parse(String raw) {
    final value = raw.trim();
    final dot = value.indexOf('.');
    if (dot <= 0 || dot != value.lastIndexOf('.')) {
      throw const ApiKeyFormatException(
        'The API key must look like phone.<64 hex characters>.',
      );
    }
    final kid = value.substring(0, dot);
    final secret = value.substring(dot + 1);
    if (!_kidPattern.hasMatch(kid)) {
      throw const ApiKeyFormatException('The API key has an invalid key id.');
    }
    if (!_secretPattern.hasMatch(secret)) {
      throw const ApiKeyFormatException(
        'The API key secret must be 64 lowercase hex characters.',
      );
    }
    return ApiKey._(kid, secret, _decodeHex(secret));
  }

  /// Parses a Settings value, which must be a `phone` key.
  factory ApiKey.parsePhone(String raw) {
    final key = ApiKey.parse(raw);
    if (key.kid != phoneKid) {
      throw const ApiKeyFormatException(
        'This app needs the phone API key. Re-enter the new phone API key.',
      );
    }
    return key;
  }

  /// Returns null when [raw] is a valid phone key, otherwise the reason.
  static String? validatePhone(String raw) {
    try {
      ApiKey.parsePhone(raw);
      return null;
    } on ApiKeyFormatException catch (error) {
      return error.message;
    }
  }
}

Uint8List _decodeHex(String hex) {
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

typedef EpochSecondsFn = int Function();

typedef NonceHexFn = String Function();

/// Builds the authorization headers for one fixed request.
class RequestSigner {
  RequestSigner({EpochSecondsFn? now, NonceHexFn? nonce})
    : _now = now ?? _utcEpochSeconds,
      _nonce = nonce ?? _randomNonceHex;

  static const String authHeaderName = 'X-Heliolytics-Auth';
  static const String contentShaHeaderName = 'X-Heliolytics-Content-SHA256';

  final EpochSecondsFn _now;
  final NonceHexFn _nonce;

  /// Headers for [request]; each call uses a fresh timestamp and nonce.
  Map<String, String> authHeaders({
    required ApiKey key,
    required SignedRequest request,
  }) {
    final ts = _now();
    final nonce = _nonce();
    final canonical = canonicalText(
      kid: key.kid,
      ts: ts,
      nonce: nonce,
      method: request.method,
      escapedPath: request.escapedPath,
      rawQuery: request.rawQuery,
      bodySha256Hex: request.bodySha256Hex,
      contentType: request.contentType,
    );
    final signature = Hmac(
      sha256,
      key.secretBytes,
    ).convert(utf8.encode(canonical)).toString();
    return {
      authHeaderName: '${key.kid}.$ts.$nonce.$signature',
      contentShaHeaderName: request.bodySha256Hex,
    };
  }
}

int _utcEpochSeconds() => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

String _randomNonceHex() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// The exact string to sign. It never has an extra trailing newline.
String canonicalText({
  required String kid,
  required int ts,
  required String nonce,
  required String method,
  required String escapedPath,
  required String rawQuery,
  required String bodySha256Hex,
  required String contentType,
}) {
  return <String>[
    kid,
    '$ts',
    nonce,
    method.toUpperCase(),
    escapedPath,
    rawQuery,
    bodySha256Hex.toLowerCase(),
    contentType,
  ].join('\n');
}
