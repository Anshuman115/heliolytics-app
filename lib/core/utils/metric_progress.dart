import 'package:heliolytics/core/constants.dart';

enum MetricKind { sleep, stress, hrv, pai, restingHr, readiness }

double metricProgress(MetricKind kind, int? value) {
  final v = value ?? 0;
  return switch (kind) {
    MetricKind.sleep => (v / metricProgressSleepMax).clamp(0.0, 1.0),
    MetricKind.stress => (1 - v / metricProgressStressMax).clamp(0.0, 1.0),
    MetricKind.hrv => (v / metricProgressHrvMax).clamp(0.0, 1.0),
    MetricKind.pai => (v / metricProgressPaiMax).clamp(0.0, 1.0),
    MetricKind.readiness => (v / metricProgressSleepMax).clamp(0.0, 1.0),
    MetricKind.restingHr =>
      (1 - (v - metricProgressRhrMin) / (metricProgressRhrMax - metricProgressRhrMin))
          .clamp(0.0, 1.0),
  };
}
