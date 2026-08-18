import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/models/health_sample.dart';
import 'package:heliolytics/utils/canvas_text.dart';
import 'package:heliolytics/utils/stress_zones.dart';
import 'package:heliolytics/widgets/stress/stress_zone_color.dart';

/// A shaded span behind the trace — a sleep or workout window.
class StressSpan {
  final DateTime start;
  final DateTime end;
  const StressSpan({required this.start, required this.end});
}

/// Stress across one day, coloured by band, with sleep/activity windows shaded.
class StressDayChart extends StatelessWidget {
  final List<HealthSample> samples;
  final List<StressSpan> spans;

  const StressDayChart({
    super.key,
    required this.samples,
    this.spans = const [],
  });

  static const _height = 200.0;

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: _height,
      child: CustomPaint(
        painter: _StressChartPainter(samples: samples, spans: spans),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StressChartPainter extends CustomPainter {
  _StressChartPainter({required this.samples, required this.spans});

  final List<HealthSample> samples;
  final List<StressSpan> spans;

  static const _padL = 30.0;
  static const _padR = 6.0;
  static const _padT = 6.0;
  static const _padB = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = size.width - _padL - _padR;
    final plotH = size.height - _padT - _padB;
    if (plotW <= 0 || plotH <= 0) return;

    final first = samples.first.sampledAt;
    final last = samples.last.sampledAt;
    final spanMs = last.difference(first).inMilliseconds;
    if (spanMs <= 0) return;

    double xOf(DateTime t) =>
        _padL + plotW * (t.difference(first).inMilliseconds / spanMs);
    double yOf(double v) =>
        _padT + plotH * (1 - (v / stressGaugeMax).clamp(0.0, 1.0));

    _paintSpans(canvas, size, xOf);
    _paintGrid(canvas, size, yOf);
    _paintTrace(canvas, xOf, yOf);
    _paintTimeLabels(canvas, size, first, last);
  }

  void _paintSpans(Canvas canvas, Size size, double Function(DateTime) xOf) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    final plotLeft = _padL;
    final plotRight = size.width - _padR;
    for (final s in spans) {
      final l = xOf(s.start).clamp(plotLeft, plotRight).toDouble();
      final r = xOf(s.end).clamp(plotLeft, plotRight).toDouble();
      if (r <= l) continue;
      canvas.drawRect(
        Rect.fromLTRB(l, _padT, r, size.height - _padB),
        paint,
      );
    }
  }

  void _paintGrid(Canvas canvas, Size size, double Function(double) yOf) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    final style = TextStyle(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 9,
    );
    for (final v in [0.0, stressMediumMin, stressHighMin, stressGaugeMax]) {
      final y = yOf(v);
      canvas.drawLine(Offset(_padL, y), Offset(size.width - _padR, y), grid);
      paintCanvasText(canvas, v.toStringAsFixed(0), Offset(0, y - 6), style,
          width: _padL - 6, align: TextAlign.right);
    }
  }

  void _paintTrace(
    Canvas canvas,
    double Function(DateTime) xOf,
    double Function(double) yOf,
  ) {
    // One segment per gap-free pair, coloured by the band it sits in, so the
    // trace reads as bands rather than a single undifferentiated line.
    for (var i = 0; i < samples.length - 1; i++) {
      final a = samples[i];
      final b = samples[i + 1];
      if (b.sampledAt.difference(a.sampledAt).inMinutes > stressTraceGapMins) {
        continue; // off-wrist gap — do not bridge it
      }
      canvas.drawLine(
        Offset(xOf(a.sampledAt), yOf(a.value)),
        Offset(xOf(b.sampledAt), yOf(b.value)),
        Paint()
          ..color = stressZoneColor(stressZoneOf(a.value))
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintTimeLabels(Canvas canvas, Size size, DateTime a, DateTime b) {
    final style = TextStyle(
      color: Colors.white.withValues(alpha: 0.45),
      fontSize: 10,
    );
    final f = DateFormat.jm();
    paintCanvasText(canvas, f.format(a), Offset(_padL, size.height - 13), style);
    paintCanvasText(canvas, f.format(b), Offset(size.width - _padR - 60, size.height - 13),
        style, width: 60, align: TextAlign.right);
  }

  @override
  bool shouldRepaint(covariant _StressChartPainter old) =>
      old.samples != samples || old.spans != spans;
}
