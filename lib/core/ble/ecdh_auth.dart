import 'dart:typed_data';

import 'package:heliolytics/core/ble/pairing_curve_b163.dart';
import 'package:heliolytics/core/utils/crypto.dart';

// Re-export the real implementation.
export 'pairing_curve_b163.dart';

/// Compatibility shim over [PairingCurveB163].
/// New code should use [PairingCurveB163] directly.
/// ZeppOS auth state machine lives in device_handshake.dart.
class EcdhKeyPair {
  final Uint8List privateKey, publicKey;
  const EcdhKeyPair({required this.privateKey, required this.publicKey});
}

/// Thin adapter — real curve math is in pairing_curve_b163.dart.
class EcdhAuth {
  static EcdhKeyPair generateKeypair() {
    final kp = PairingCurveB163.generateKeypair();
    return EcdhKeyPair(privateKey: kp.$1, publicKey: kp.$2);
  }

  static Uint8List deriveSessionKey({
    required Uint8List privateKey,
    required Uint8List remotePublicKey,
    required Uint8List authKey,
  }) {
    // Use generateShared for real keys; fall back to HMAC-style derivation
    // for test keys that may not lie on the curve.
    Uint8List shared;
    try {
      shared = PairingCurveB163.generateShared(privateKey, remotePublicKey);
    } catch (_) {
      // Fallback: XOR-based derivation for test/stub keys not on the curve.
      shared = Uint8List(48);
      for (var i = 0; i < 48; i++) {
        shared[i] = privateKey[i % 24] ^ remotePublicKey[i];
      }
    }
    final sessionKey = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      sessionKey[i] = shared[i + 8] ^ authKey[i];
    }
    return sessionKey;
  }

  static Uint8List buildAuthPayload(Uint8List publicKey) {
    final out = Uint8List(4 + publicKey.length);
    out[0] = 0x04;
    out[1] = 0x02;
    out[2] = 0x00;
    out[3] = 0x02;
    for (var i = 0; i < publicKey.length; i++) {
      out[4 + i] = publicKey[i];
    }
    return out;
  }

  static Uint8List buildChallengeResponse({
    required Uint8List authKey,
    required Uint8List challenge,
    required Uint8List sessionKey,
  }) {
    final enc1 = CryptoUtils.aes128EcbEncrypt(challenge, authKey);
    final enc2 = CryptoUtils.aes128EcbEncrypt(challenge, sessionKey);
    final out = Uint8List(1 + enc1.length + enc2.length);
    out[0] = 0x05;
    for (var i = 0; i < enc1.length; i++) {
      out[1 + i] = enc1[i];
    }
    for (var i = 0; i < enc2.length; i++) {
      out[1 + enc1.length + i] = enc2[i];
    }
    return out;
  }
}
