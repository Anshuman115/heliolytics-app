class SyncCoverage {
  final DateTime? dataThrough;
  final DateTime? lastIngestAt;
  final bool hasData;

  const SyncCoverage({
    this.dataThrough,
    this.lastIngestAt,
    this.hasData = false,
  });

  factory SyncCoverage.fromJson(Map<String, dynamic> j) => SyncCoverage(
        dataThrough: j['dataThrough'] != null
            ? DateTime.parse(j['dataThrough'] as String).toLocal()
            : null,
        lastIngestAt: j['lastIngestAt'] != null
            ? DateTime.parse(j['lastIngestAt'] as String).toLocal()
            : null,
        hasData: j['hasData'] as bool? ?? false,
      );
}
