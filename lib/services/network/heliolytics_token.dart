import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Mints `X-Heliolytics-Token` — must match Go `auth.SignToken` / web signing.
String mintHeliolyticsToken(String secret) {
  final ts = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final nonce = _randomHex(16);
  final sig = Hmac(sha256, utf8.encode(secret))
      .convert(utf8.encode('$ts:$nonce'))
      .toString();
  return '$ts.$nonce.$sig';
}

String _randomHex(int byteCount) {
  final r = Random.secure();
  final b = List<int>.generate(byteCount, (_) => r.nextInt(256));
  return b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
}
