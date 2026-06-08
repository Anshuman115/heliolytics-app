import 'dart:typed_data';
import 'package:pointycastle/export.dart';

// CRC-32 (IEEE, zlib/ISO-HDLC) — used in Huami chunked frame trailer.
// CRC32 for Huami chunk checksums (Gadgetbridge-compatible polynomial).
final List<int> _crc32Table = _buildCrc32Table();
List<int> _buildCrc32Table() {
  final t = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    }
    t[n] = c;
  }
  return t;
}

/// CRC-32 (IEEE, zlib) — used in Huami chunked frame trailer.
int crc32Huami(Uint8List data, [int start = 0, int? end]) {
  end ??= data.length;
  var crc = 0xFFFFFFFF;
  for (var i = start; i < end; i++) {
    crc = _crc32Table[(crc ^ data[i]) & 0xFF] ^ (crc >>> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

class CryptoUtils {
  static String bytesToHex(Uint8List bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  static Uint8List hexToBytes(String hex) {
    if (hex.length % 2 != 0) {
      throw FormatException('Hex string must have even length (got ${hex.length}).');
    }
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      final v = int.tryParse(hex.substring(i * 2, i * 2 + 2), radix: 16);
      if (v == null) throw FormatException('Invalid hex at ${i * 2}');
      out[i] = v;
    }
    return out;
  }

  static Uint8List aes128EcbEncrypt(Uint8List input, Uint8List key) {
    if (key.length != 16) {
      throw ArgumentError('AES key must be 16 bytes (got ${key.length}).');
    }
    if (input.isEmpty || input.length % 16 != 0) {
      throw ArgumentError(
          'AES input must be a non-zero multiple of 16 bytes (got ${input.length}).');
    }
    final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(key));
    final out = Uint8List(input.length);
    for (var off = 0; off < input.length; off += 16) {
      cipher.processBlock(input, off, out, off);
    }
    return out;
  }

  static Uint8List aes128EcbDecrypt(Uint8List input, Uint8List key) {
    if (key.length != 16) {
      throw ArgumentError('AES key must be 16 bytes (got ${key.length}).');
    }
    if (input.isEmpty || input.length % 16 != 0) {
      throw ArgumentError(
          'AES input must be a non-zero multiple of 16 bytes (got ${input.length}).');
    }
    final cipher = ECBBlockCipher(AESEngine())..init(false, KeyParameter(key));
    final out = Uint8List(input.length);
    for (var off = 0; off < input.length; off += 16) {
      cipher.processBlock(input, off, out, off);
    }
    return out;
  }
}
