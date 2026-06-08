import 'dart:typed_data';
import 'package:heliolytics/core/utils/crypto.dart';

// ─── Huami-2021 / ZeppOS Chunked Transport ────────────────────────────────
// Multiplexes logical "endpoints" (auth=0x0082, fetch-control=0x004b, …)
// over one GATT char pair: 0x0016 (write) and 0x0017 (notify).
//
// Each logical message is split into BLE-sized chunks with a small header:
//   byte 0    = 0x03 (framing marker)
//   byte 1    = flags: bit0=first, bit1=last, bit2=needsAck, bit3=encrypted
//   byte 2    = 0x00 (reserved)
//   byte 3    = write handle (increments per message, wraps at 255)
//   byte 4    = chunk counter within this message
//   bytes 5-10 (first chunk only) = 4-byte LE original length + 2-byte LE endpoint
//
// Encryption (post-auth):
//   message key = sessionKey[i] ^ writeHandle  (per-message AES-128-ECB key)
//   plaintext   = data ‖ seq(4 LE) ‖ crc32(4 LE), zero-padded to 16-byte multiple
//   The length field in the frame header stays the ORIGINAL (decrypted) length.
//

class GattChunkEncoder {
  int mtu;
  int _writeHandle = 0;
  Uint8List? _sessionKey;
  int _sequence = 0;

  GattChunkEncoder({this.mtu = 247});

  void setEncryption(Uint8List sessionKey, int sequence) {
    _sessionKey = sessionKey;
    _sequence = sequence;
  }

  List<Uint8List> encode(int endpoint, Uint8List data, {bool encrypt = false}) {
    _writeHandle = (_writeHandle + 1) & 0xFF;
    final int originalLength = data.length;

    Uint8List toSend = data;
    if (encrypt) {
      final key = _sessionKey;
      if (key == null) throw StateError('encrypt requested without session key');
      final messageKey = Uint8List(16);
      for (var i = 0; i < 16; i++) {
        messageKey[i] = key[i] ^ _writeHandle;
      }
      // Plaintext = data(originalLength) + seq(4 bytes) + crc32(4 bytes) = +8.
      // Then zero-pad to the next 16-byte multiple for AES-128 block alignment.
      var encLen = originalLength + 8;
      final overflow = encLen % 16;
      if (overflow > 0) encLen += 16 - overflow;
      final plain = Uint8List(encLen);
      plain.setRange(0, originalLength, data);
      final seq = _sequence & 0xFFFFFFFF;
      _sequence++;
      plain[originalLength]     = seq & 0xff;
      plain[originalLength + 1] = (seq >> 8) & 0xff;
      plain[originalLength + 2] = (seq >> 16) & 0xff;
      plain[originalLength + 3] = (seq >> 24) & 0xff;
      final crc = crc32Huami(plain, 0, originalLength + 4);
      plain[originalLength + 4] = crc & 0xff;
      plain[originalLength + 5] = (crc >> 8) & 0xff;
      plain[originalLength + 6] = (crc >> 16) & 0xff;
      plain[originalLength + 7] = (crc >> 24) & 0xff;
      // Note: aes128EcbEncrypt(input, key) — input first, key second.
      toSend = CryptoUtils.aes128EcbEncrypt(plain, messageKey);
    }

    final chunks = <Uint8List>[];
    var remaining = toSend.length;
    var offset = 0;
    var count = 0;
    do {
      final first = count == 0;
      // First chunk header = 5 common bytes + 6 bytes (length+endpoint) = 11 bytes.
      // Subsequent chunk headers = 5 common bytes only.
      final header = first ? 11 : 5;
      // mtu - 3: BLE ATT overhead is 3 bytes (opcode + handle), leaving mtu-3 for the chunk.
      var maxPayload = (mtu - 3) - header;
      if (maxPayload < 1) maxPayload = 1;
      final take = remaining < maxPayload ? remaining : maxPayload;
      var flags = first ? 0x01 : 0x00; // bit0 = isFirst
      if (encrypt) flags |= 0x08;       // bit3 = encrypted
      if (remaining <= maxPayload) {
        flags |= 0x02; // bit1 = isLast
        flags |= 0x04; // bit2 = needsAck (always set on last chunk)
      }
      final b = BytesBuilder();
      b.add([0x03, flags, 0x00, _writeHandle & 0xFF, count & 0xFF]);
      if (first) {
        final h = ByteData(6);
        h.setUint32(0, originalLength, Endian.little); // ORIGINAL length
        h.setUint16(4, endpoint, Endian.little);
        b.add(h.buffer.asUint8List());
      }
      if (take > 0) b.add(Uint8List.sublistView(toSend, offset, offset + take));
      chunks.add(b.toBytes());
      offset += take;
      remaining -= take;
      count += 1;
    } while (remaining > 0);
    return chunks;
  }
}

typedef HuamiFrame = ({
  int endpoint,
  Uint8List payload,
  bool encrypted,
  bool needsAck,
  int handle,
  int count,
});

class GattChunkDecoder {
  int? _handle;
  int _type = 0;
  int _length = 0; // original (decrypted) length
  bool _encrypted = false;
  final BytesBuilder _buf = BytesBuilder();

  /// Feed one notification value from char 0x0017.
  /// Returns the fully reassembled frame on the last chunk, null otherwise.
  HuamiFrame? feed(Uint8List data, {Uint8List? sessionKey}) {
    if (data.length < 5 || data[0] != 0x03) return null;
    var i = 1;
    final flags = data[i++];
    final encrypted = (flags & 0x08) != 0;
    final first = (flags & 0x01) != 0;
    final last = (flags & 0x02) != 0;
    final needsAck = (flags & 0x04) != 0;
    i++; // reserved byte
    final handle = data[i++];
    final count = data[i++];
    if (_handle != null && _handle != handle) return null;
    if (first) {
      if (data.length < i + 6) return null;
      final bd = ByteData.sublistView(data, i, i + 6);
      final originalLen = bd.getUint32(0, Endian.little);
      _length = originalLen;
      _type = bd.getUint16(4, Endian.little);
      _encrypted = encrypted;
      _buf.clear();
      _handle = handle;
      i += 6;
    }
    if (i > data.length) return null;
    _buf.add(Uint8List.sublistView(data, i, data.length));
    if (last) {
      var all = _buf.toBytes();
      if (_encrypted) {
        if (sessionKey == null) {
          _reset();
          return null;
        }
        final messageKey = Uint8List(16);
        for (var j = 0; j < 16; j++) {
          messageKey[j] = sessionKey[j] ^ handle;
        }
        // ciphertext length = padded(originalLength + 8)
        var encLen = _length + 8;
        final overflow = encLen % 16;
        if (overflow > 0) encLen += 16 - overflow;
        if (all.length < encLen) {
          _reset();
          return null;
        }
        // Note: aes128EcbDecrypt(input, key) — input first, key second.
        all = CryptoUtils.aes128EcbDecrypt(
            Uint8List.sublistView(all, 0, encLen), messageKey);
      }
      final end = _length <= all.length ? _length : all.length;
      final payload = Uint8List.fromList(all.sublist(0, end));
      final frame = (
        endpoint: _type,
        payload: payload,
        encrypted: _encrypted,
        needsAck: needsAck,
        handle: handle,
        count: count,
      );
      _reset();
      return frame;
    }
    return null;
  }

  void _reset() {
    _handle = null;
    _type = 0;
    _length = 0;
    _encrypted = false;
    _buf.clear();
  }
}
