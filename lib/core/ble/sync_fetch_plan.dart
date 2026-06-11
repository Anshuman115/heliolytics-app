class SyncFetchPlan {
  final DateTime since;
  final String logLine;
  final DateTime? backendDataThrough;

  const SyncFetchPlan({
    required this.since,
    required this.logLine,
    this.backendDataThrough,
  });
}
