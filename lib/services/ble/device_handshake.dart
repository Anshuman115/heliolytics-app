import 'dart:typed_data';

import 'package:heliolytics/services/ble/pairing_curve_b163.dart';
import 'package:heliolytics/services/ble/gatt_framing.dart';
import 'package:heliolytics/utils/crypto.dart';

enum AuthState { idle, sentPubKey, sentSessionKey, success, failed }

/// ZeppOS / Huami-2021 auth handshake over logical endpoint 0x0082.
/// Transport-agnostic: the caller provides [writeChunk] (writes one BLE chunk
/// to char 0x0016) and feeds notifications from char 0x0017 into [onNotify].
///
/// On success, [sessionKey] (16 bytes) and [sequence] (uint32) are set — these
/// drive AES encryption/decryption of post-auth frames.
/// See research/protocol/zeppos_ble_handshake.md.
class DeviceHandshake {
  static const int endpoint = 0x0082;

  final Uint8List authKey; // 16 bytes
  final Future<void> Function(Uint8List chunk) writeChunk;
  final void Function(String msg)? log;
  void Function()? onSuccess;
  void Function(String reason)? onFailure;

  final GattChunkEncoder _encoder = GattChunkEncoder();
  final GattChunkDecoder _decoder = GattChunkDecoder();

  Uint8List? _priv;
  Uint8List? _pub;
  Uint8List? sessionKey;
  int? sequence;
  AuthState state = AuthState.idle;

  DeviceHandshake({
    required this.authKey,
    required this.writeChunk,
    this.log,
    this.onSuccess,
    this.onFailure,
  }) {
    if (authKey.length != 16) {
      throw ArgumentError('authKey must be 16 bytes');
    }
  }

  Future<void> start() async {
    final kp = PairingCurveB163.generateKeypair();
    _priv = kp.$1;
    _pub = kp.$2;
    final payload = Uint8List(52)
      ..setRange(0, 4, const [0x04, 0x02, 0x00, 0x02])
      ..setRange(4, 52, _pub!);
    state = AuthState.sentPubKey;
    log?.call('auth: sending public key');
    await _send(payload);
  }

  Future<void> _send(Uint8List payload) async {
    for (final chunk in _encoder.encode(endpoint, payload)) {
      await writeChunk(chunk);
    }
  }

  /// Feed every notification value from char 0x0017 here.
  void onNotify(Uint8List value) {
    final frame = _decoder.feed(value);
    if (frame == null || frame.endpoint != endpoint) return;
    final p = frame.payload;
    if (p.length < 3 || p[0] != 0x10) {
      log?.call('auth: unexpected frame ${_hex(p)}');
      return;
    }
    final cmd = p[1];
    final status = p[2];
    if (cmd == 0x04) {
      _handlePubKeyReply(status, p);
    } else if (cmd == 0x05) {
      _handleSessionReply(status, p);
    }
  }

  void _handlePubKeyReply(int status, Uint8List p) {
    if (status != 0x01) {
      _fail('pub-key reply status=0x${status.toRadixString(16)}');
      return;
    }
    if (p.length < 67) {
      _fail('pub-key reply too short (${p.length})');
      return;
    }
    final random = Uint8List.fromList(p.sublist(3, 19));
    final remotePub = Uint8List.fromList(p.sublist(19, 67));
    final shared = PairingCurveB163.generateShared(_priv!, remotePub);
    sequence = ByteData.sublistView(shared, 0, 4).getUint32(0, Endian.little);
    final session = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      session[i] = shared[i + 8] ^ authKey[i];
    }
    sessionKey = session;
    // Note: CryptoUtils.aes128EcbEncrypt(input, key) — input first, key second.
    final enc1 = CryptoUtils.aes128EcbEncrypt(random, authKey);
    final enc2 = CryptoUtils.aes128EcbEncrypt(random, session);
    final cmd = Uint8List(33)
      ..[0] = 0x05
      ..setRange(1, 17, enc1)
      ..setRange(17, 33, enc2);
    state = AuthState.sentSessionKey;
    log?.call('auth: derived session key, sending proof');
    _send(cmd);
  }

  void _handleSessionReply(int status, Uint8List p) {
    if (status == 0x25) {
      _fail('wrong auth key');
      return;
    }
    if (status != 0x01) {
      _fail('session reply status=0x${status.toRadixString(16)}');
      return;
    }
    state = AuthState.success;
    log?.call('auth: SUCCESS');
    onSuccess?.call();
  }

  void _fail(String reason) {
    state = AuthState.failed;
    log?.call('auth: FAILED — $reason');
    onFailure?.call(reason);
  }

  static String _hex(Uint8List b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
}
