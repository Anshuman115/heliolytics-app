import 'package:flutter/material.dart';

import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/utils/formatters.dart';
import 'package:heliolytics/models/sleep_stage.dart';

/// Timeline hypnogram: time on X, stage on Y.
class SleepHypnogramChart extends StatelessWidget {
  const SleepHypnogramChart({super.key, required this.stages});

  final List<SleepStagePoint> stages;

  static const _height = 140.0;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) {
      return const SizedBox(
        height: _height,
        child: Center(child: Text('No stage timeline')),
      );
    }
    final sorted = List<SleepStagePoint>.from(stages)
      ..sort((a, b) => a.start.compareTo(b.start));
    final t0 = sorted.first.start;
    final t1 = sorted.last.end;
    final spanMs = t1.difference(t0).inMilliseconds.clamp(1, 1 << 31);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _height,
          child: CustomPaint(
            painter: _HypnogramPainter(stages: sorted, t0: t0, spanMs: spanMs),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: HelioSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatWorkoutTime(t0), style: Theme.of(context).textTheme.labelSmall),
            Text(formatWorkoutTime(t1), style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: HelioSpacing.sm),
        Wrap(
          spacing: HelioSpacing.lg,
          runSpacing: HelioSpacing.xs,
          children: SleepStageKind.values
              .where((k) => k != SleepStageKind.unknown)
              .map((k) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: k.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(k.label, style: Theme.of(context).textTheme.labelSmall),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _HypnogramPainter extends CustomPainter {
  _HypnogramPainter({
    required this.stages,
    required this.t0,
    required this.spanMs,
  });

  final List<SleepStagePoint> stages;
  final DateTime t0;
  final int spanMs;

  static const _labels = ['Awake', 'REM', 'Light', 'Deep'];

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 52.0;
    const padR = 8.0;
    const padT = 8.0;
    const padB = 8.0;
    final plotW = size.width - padL - padR;
    final plotH = size.height - padT - padB;
    if (plotW <= 0 || plotH <= 0) return;

    final grid = Paint()
      ..color = const Color(0x16FFFFFF)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 10,
    );

    final rowH = plotH / _labels.length;
    for (var i = 0; i < _labels.length; i++) {
      final y = padT + rowH * (i + 0.5);
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), grid);
      _paintText(canvas, _labels[i], Offset(4, y - 6), labelStyle);
    }

    double xFor(DateTime t) =>
        padL + plotW * t.difference(t0).inMilliseconds / spanMs;
    double yFor(int band) => padT + rowH * (band + 0.5);

    // Build a stepped path that follows the stage timeline (awake top →
    // deep bottom), plus a matching fill path down to the baseline.
    final line = Path();
    final fill = Path();
    final baseline = padT + plotH;
    var started = false;
    var lastX = padL;
    for (final s in stages) {
      final y = yFor(s.kind.bandIndex);
      final x0 = xFor(s.start);
      final x1 = xFor(s.end);
      if (!started) {
        line.moveTo(x0, y);
        fill.moveTo(x0, baseline);
        fill.lineTo(x0, y);
        started = true;
      } else {
        line.lineTo(x0, y); // vertical step into the new stage
        fill.lineTo(x0, y);
      }
      line.lineTo(x1, y);
      fill.lineTo(x1, y);
      lastX = x1;
    }
    if (!started) return;
    fill.lineTo(lastX, baseline);
    fill.close();

    final plotRect = Rect.fromLTWH(padL, padT, plotW, plotH);
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HelioColors.sleepRem.withValues(alpha: 0.35),
            HelioColors.sleepRem.withValues(alpha: 0.02),
          ],
        ).createShader(plotRect),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = HelioColors.sleepRem
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintText(Canvas canvas, String text, Offset at, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _HypnogramPainter old) =>
      old.stages != stages || old.t0 != t0;
}
