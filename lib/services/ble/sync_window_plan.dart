class SyncWindowPlan {
  final DateTime anchorSince;
  final Map<String, DateTime> perTypeSince;
  final List<String> logLines;
  final DateTime? backendDataThrough;

  const SyncWindowPlan({
    required this.anchorSince,
    required this.perTypeSince,
    required this.logLines,
    this.backendDataThrough,
  });
}
