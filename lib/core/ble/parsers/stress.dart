import 'dart:typed_data';

import 'package:heliolytics/core/ble/sync_page_anchor.dart';

/// Stress (0x13) — 1 byte per minute, round-relative timestamps.
/// Auto stress samples from type code 0x13 (4 bytes per minute).
class StressSample {
  final DateTime timestamp;
  final int value;
  const StressSample(this.timestamp, this.value);
}

class StressParser {
  static List<StressSample> parseMulti(
    Uint8List bytes,
    List<SyncPageAnchor> segments,
  ) {
    if (segments.isEmpty) return [];
    final out = <StressSample>[];
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

  static List<StressSample> parse(Uint8List bytes, DateTime roundStart) {
    final out = <StressSample>[];
    var ts = roundStart;
    for (final b in bytes) {
      if (b != 0xFF) out.add(StressSample(ts, b));
      ts = ts.add(const Duration(minutes: 1));
    }
    return out;
  }
}
