import 'package:flutter/material.dart';

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
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 10,
    );

    for (var i = 0; i < _labels.length; i++) {
      final y = padT + plotH * (i + 0.5) / _labels.length;
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), grid);
      _paintText(canvas, _labels[i], Offset(4, y - 6), labelStyle);
    }

    for (final s in stages) {
      final x0 = padL +
          plotW * s.start.difference(t0).inMilliseconds / spanMs;
      final x1 = padL +
          plotW * s.end.difference(t0).inMilliseconds / spanMs;
      final w = (x1 - x0).clamp(1.0, plotW);
      final band = s.kind.bandIndex;
      final rowH = plotH / _labels.length;
      final y = padT + band * rowH + 2;
      final h = rowH - 4;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x0, y, w, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(r, Paint()..color = s.kind.color);
    }
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
