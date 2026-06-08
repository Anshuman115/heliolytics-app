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
        'roundStart': roundStart.toIso8601String(),
      };

  factory SyncPageAnchor.fromJson(Map<String, dynamic> j) =>
      SyncPageAnchor(
        byteOffset: (j['byteOffset'] as num).toInt(),
        roundStart: DateTime.parse(j['roundStart'] as String),
      );
}
