import 'package:heliolytics/core/utils/ist_time.dart' show formatRoundStartIst, parseRoundStartIst;

/// One page of a paged Huami activity-fetch (byte offset + roundStart anchor).
/// Each round has its own device-reported [roundStart].
class SyncPageAnchor {
  final int byteOffset;
  final DateTime roundStart;

  const SyncPageAnchor({
    required this.byteOffset,
    required this.roundStart,
  });

  Map<String, dynamic> toJson() => {
        'byteOffset': byteOffset,
        'roundStart': formatRoundStartIst(roundStart),
      };

  factory SyncPageAnchor.fromJson(Map<String, dynamic> j) =>
      SyncPageAnchor(
        byteOffset: (j['byteOffset'] as num).toInt(),
        roundStart: parseRoundStartIst(j['roundStart'] as String),
      );
}
