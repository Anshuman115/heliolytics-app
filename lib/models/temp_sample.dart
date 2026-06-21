class TempSample {
  final String dayKey;
  final DateTime sampledAt;
  final double celsius;

  const TempSample({
    required this.dayKey,
    required this.sampledAt,
    required this.celsius,
  });

  factory TempSample.fromJson(Map<String, dynamic> j) => TempSample(
        dayKey: j['dayKey'] as String,
        sampledAt: DateTime.parse(j['sampledAt'] as String).toLocal(),
        celsius: (j['celsius'] as num).toDouble(),
      );
}
