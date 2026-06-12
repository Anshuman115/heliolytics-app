class SyncFetchPlan {
  final DateTime since;
  final String logLine;
  final DateTime? backendDataThrough;
  final Map<String, DateTime?>? typeCoverage;

  const SyncFetchPlan({
    required this.since,
    required this.logLine,
    this.backendDataThrough,
    this.typeCoverage,
  });
}
