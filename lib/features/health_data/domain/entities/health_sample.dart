class HealthSample {
  final String metric;
  final String dayKey;
  final DateTime sampledAt;
  final double value;

  const HealthSample({
    required this.metric,
    required this.dayKey,
    required this.sampledAt,
    required this.value,
  });

  factory HealthSample.fromJson(Map<String, dynamic> j) => HealthSample(
        metric: j['metric'] as String? ?? '',
        dayKey: j['dayKey'] as String? ?? '',
        sampledAt: DateTime.parse(j['sampledAt'] as String).toLocal(),
        value: (j['value'] as num).toDouble(),
      );
}
