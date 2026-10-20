import 'dart:async';
import 'dart:typed_data';

import 'package:heliolytics/services/ble/gatt_framing.dart';

/// Post-auth chunked comms over chars 0x0016 (write) / 0x0017 (notify).
/// Handles fragmentation, optional AES encryption (session key), and the
/// chunked ACK the device requires (flag 0x04).
class EncryptedEndpoint {
  final GattChunkEncoder _encoder;
  final GattChunkDecoder _decoder = GattChunkDecoder();

  final Uint8List? sessionKey;
  final Future<void> Function(Uint8List) writeChunk;
  final Future<void> Function(Uint8List) writeAck;
  final void Function(int endpoint, Uint8List payload) onPayload;
  final void Function(String)? log;
  final void Function()? onSendFailure;
  Future<void> _sendQueue = Future<void>.value();
  bool _closed = false;

  EncryptedEndpoint({
    required this.writeChunk,
    required this.writeAck,
    required this.onPayload,
    this.sessionKey,
    int sequence = 0,
    int mtu = 247,
    this.log,
    this.onSendFailure,
  }) : _encoder = GattChunkEncoder(mtu: mtu) {
    if (sessionKey != null) _encoder.setEncryption(sessionKey!, sequence);
  }

  /// Serializes complete messages. Any encoding or transport failure retires
  /// this authenticated channel before queued callers can allocate a sequence.
  Future<void> send(int endpoint, Uint8List data, {bool encrypt = false}) {
    final current = _sendQueue.then<void>((_) async {
      if (_closed) throw StateError('encrypted endpoint is closed');
      try {
        for (final chunk in _encoder.encode(endpoint, data, encrypt: encrypt)) {
          if (_closed) throw StateError('encrypted endpoint is closed');
          await writeChunk(chunk);
        }
      } catch (_) {
        close();
        onSendFailure?.call();
        rethrow;
      }
    });
    _sendQueue = current.then<void>((_) {}, onError: (_, __) {});
    return current;
  }

  /// Retire the authenticated channel. Later notifications are ignored and
  /// queued sends are rejected.
  void close() {
    _closed = true;
  }

  /// Feed every notification value from char 0x0017 here.
  Future<void> onNotify(Uint8List value) async {
    if (_closed) return;
    final f = _decoder.feed(value, sessionKey: sessionKey);
    if (f == null) return;
    if (f.needsAck) {
      try {
        await writeAck(
          Uint8List.fromList([0x04, 0x00, f.handle, 0x01, f.count]),
        );
      } catch (e) {
        log?.call('ack write failed: $e');
      }
    }
    onPayload(f.endpoint, f.payload);
  }
}
