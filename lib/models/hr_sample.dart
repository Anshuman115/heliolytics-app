class HeartRateSample {
  final String dayKey;
  final DateTime sampledAt;
  final int bpm;

  const HeartRateSample({
    required this.dayKey,
    required this.sampledAt,
    required this.bpm,
  });

  factory HeartRateSample.fromJson(Map<String, dynamic> j) => HeartRateSample(
        dayKey: j['dayKey'] as String? ?? '',
        sampledAt: DateTime.parse(j['sampledAt'] as String).toLocal(),
        bpm: (j['bpm'] as num).toInt(),
      );
}
