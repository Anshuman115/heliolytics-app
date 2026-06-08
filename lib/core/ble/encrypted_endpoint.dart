import 'dart:typed_data';

import 'package:heliolytics/core/ble/protocol/gatt_framing.dart';

// ─── Post-Auth Chunked Comms ──────────────────────────────────────────────
// Sits on top of the chunked transport layer (gatt_framing.dart).
// Used after auth succeeds to send/receive structured endpoint messages.
// Handles fragmentation, optional AES encryption, and the chunked ACK the
// device requires when it sets the needsAck flag.
class EncryptedEndpoint {
  final GattChunkEncoder _encoder;
  final GattChunkDecoder _decoder = GattChunkDecoder();

  final Uint8List? sessionKey;
  final Future<void> Function(Uint8List) writeChunk; // → char 0x0016
  final Future<void> Function(Uint8List) writeAck;   // → char 0x0017
  final void Function(int endpoint, Uint8List payload) onPayload;
  final void Function(String)? log;

  EncryptedEndpoint({
    required this.writeChunk,
    required this.writeAck,
    required this.onPayload,
    this.sessionKey,
    int sequence = 0,
    int mtu = 247,
    this.log,
  }) : _encoder = GattChunkEncoder(mtu: mtu) {
    if (sessionKey != null) _encoder.setEncryption(sessionKey!, sequence);
  }

  Future<void> send(int endpoint, Uint8List data, {bool encrypt = false}) async {
    for (final chunk in _encoder.encode(endpoint, data, encrypt: encrypt)) {
      await writeChunk(chunk);
    }
  }

  /// Feed every notification value from char 0x0017 here.
  Future<void> onNotify(Uint8List value) async {
    final f = _decoder.feed(value, sessionKey: sessionKey);
    if (f == null) return;
    if (f.needsAck) {
      try {
        await writeAck(
            Uint8List.fromList([0x04, 0x00, f.handle, 0x01, f.count]));
      } catch (e) {
        log?.call('ack write failed: $e');
      }
    }
    onPayload(f.endpoint, f.payload);
  }
}
