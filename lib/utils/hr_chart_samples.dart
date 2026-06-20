import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/models/hr_sample.dart';

List<HealthSample> heartRateAsChartSamples(List<HeartRateSample> samples) {
  return samples
      .map(
        (h) => HealthSample(
          metric: 'hr',
          dayKey: h.dayKey,
          sampledAt: h.sampledAt,
          value: h.bpm.toDouble(),
        ),
      )
      .toList();
}
