import 'dart:typed_data';

/// Live heart rate via standard BLE HR Measurement profile (0x2a37).
/// Format: [flags(1), hr_value(1 or 2)]
/// Bit 0 of flags: 0 = hr is u8, 1 = hr is u16 LE
/// Phase 2: parse this instead of using UnknownParser.
// TODO(phase2): implement LiveHrParser
class LiveHrParser {
  static int? parse(Uint8List bytes) {
    if (bytes.isEmpty) return null;
    final flags = bytes[0];
    final isU16 = (flags & 0x01) != 0;
    if (isU16 && bytes.length >= 3) {
      return ByteData.sublistView(bytes, 1, 3).getUint16(0, Endian.little);
    } else if (!isU16 && bytes.length >= 2) {
      return bytes[1];
    }
    return null;
  }
}
