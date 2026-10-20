import 'package:heliolytics/models/protocol_exception.dart';

/// C3 coverage response. `lastIngestAt` is the only confirmed-sync timestamp.
class SyncCoverage {
  const SyncCoverage({
    required this.hasData,
    required this.types,
    this.lastIngestAt,
    this.dataThrough,
  });

  /// Every measured type code the server reports, in contract order.
  static const List<String> measuredTypeCodes = [
    '0x01',
    '0x05',
    '0x06',
    '0x0D',
    '0x13',
    '0x25',
    '0x2E',
    '0x38',
    '0x46',
    '0x48',
    '0x49',
  ];

  final bool hasData;
  final DateTime? lastIngestAt;

  /// Display-only overall watermark. Never a per-type fetch cursor.
  final DateTime? dataThrough;
  final Map<String, DateTime?> types;

  factory SyncCoverage.fromJson(Map<String, dynamic> j) {
    final hasData = j['hasData'];
    if (hasData is! bool) {
      throw const ProtocolException('Coverage response has no hasData flag');
    }
    final rawTypes = j['types'];
    if (rawTypes is! Map) {
      throw const ProtocolException('Coverage response has no types map');
    }
    final keys = rawTypes.keys.map((k) => k.toString()).toSet();
    final expected = measuredTypeCodes.toSet();
    if (keys.length != expected.length || !keys.containsAll(expected)) {
      throw const ProtocolException(
        'Coverage response has an unexpected type set',
      );
    }
    final types = <String, DateTime?>{};
    for (final code in measuredTypeCodes) {
      types[code] = _timestamp(rawTypes[code], code);
    }
    return SyncCoverage(
      hasData: hasData,
      types: types,
      lastIngestAt: _timestamp(j['lastIngestAt'], 'lastIngestAt'),
      dataThrough: _timestamp(j['dataThrough'], 'dataThrough'),
    );
  }

  Map<String, dynamic> toJson() => {
    'hasData': hasData,
    'lastIngestAt': lastIngestAt?.toUtc().toIso8601String(),
    'dataThrough': dataThrough?.toUtc().toIso8601String(),
    'types': {
      for (final code in measuredTypeCodes)
        code: types[code]?.toUtc().toIso8601String(),
    },
  };
}

DateTime? _timestamp(Object? raw, String field) {
  if (raw == null) return null;
  if (raw is! String) {
    throw ProtocolException('Coverage $field is not a timestamp');
  }
  return DateTime.parse(raw).toUtc();
}
