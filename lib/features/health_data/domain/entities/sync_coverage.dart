class SyncCoverage {
  final DateTime? dataThrough;
  final DateTime? lastIngestAt;
  final bool hasData;
  final Map<String, DateTime?> types;

  const SyncCoverage({
    this.dataThrough,
    this.lastIngestAt,
    this.hasData = false,
    this.types = const {},
  });

  factory SyncCoverage.fromJson(Map<String, dynamic> j) => SyncCoverage(
        dataThrough: j['dataThrough'] != null
            ? DateTime.parse(j['dataThrough'] as String).toLocal()
            : null,
        lastIngestAt: j['lastIngestAt'] != null
            ? DateTime.parse(j['lastIngestAt'] as String).toLocal()
            : null,
        hasData: j['hasData'] as bool? ?? false,
        types: _parseTypes(j['types']),
      );
}

Map<String, DateTime?> _parseTypes(Object? raw) {
  if (raw is! Map) return const {};
  final out = <String, DateTime?>{};
  raw.forEach((key, value) {
    final code = key.toString();
    if (value == null) {
      out[code] = null;
      return;
    }
    if (value is String) {
      out[code] = DateTime.parse(value).toLocal();
    }
  });
  return out;
}
