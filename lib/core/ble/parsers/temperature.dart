import 'dart:typed_data';

import 'package:heliolytics/core/ble/sync_page_anchor.dart';

/// Skin temperature (0x2E) — 8 bytes per minute, round-relative timestamps.
/// Skin temperature from type code 0x2E (8 bytes per minute).
class TemperatureSample {
  final DateTime timestamp;
  final double celsius;
  const TemperatureSample(this.timestamp, this.celsius);
}

class TemperatureParser {
  static List<TemperatureSample> parseMulti(
    Uint8List bytes,
    List<SyncPageAnchor> segments,
  ) {
    if (segments.isEmpty) return [];
    final out = <TemperatureSample>[];
    for (var i = 0; i < segments.length; i++) {
      final start = segments[i].byteOffset;
      final end = i + 1 < segments.length
          ? segments[i + 1].byteOffset
          : bytes.length;
      if (start >= bytes.length) continue;
      out.addAll(parse(
        bytes.sublist(start, end.clamp(0, bytes.length)),
        segments[i].roundStart,
      ));
    }
    return out;
  }

  static List<TemperatureSample> parse(Uint8List bytes, DateTime roundStart) {
    final out = <TemperatureSample>[];
    var ts = roundStart;
    var i = 0;
    while (i + 8 <= bytes.length) {
      final raw = ByteData.sublistView(bytes, i + 2, i + 4)
          .getInt16(0, Endian.little);
      if (raw != 0x7FFF && raw != -1) {
        out.add(TemperatureSample(ts, raw / 100.0));
      }
      ts = ts.add(const Duration(minutes: 1));
      i += 8;
    }
    return out;
  }
}
