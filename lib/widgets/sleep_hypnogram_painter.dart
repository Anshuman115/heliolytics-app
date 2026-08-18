import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/models/sleep_stage.dart';

class SleepHypnogramPainter extends CustomPainter {
  SleepHypnogramPainter({
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
    for (var index = 0; index < _labels.length; index++) {
      final y = padT + rowH * (index + 0.5);
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), grid);
      _paintText(canvas, _labels[index], Offset(4, y - 6), labelStyle);
    }

    double xFor(DateTime time) =>
        padL + plotW * time.difference(t0).inMilliseconds / spanMs;
    double yFor(int band) => padT + rowH * (band + 0.5);
    final baseline = padT + plotH;
    for (final stage in stages) {
      final y = yFor(stage.kind.bandIndex);
      final x0 = xFor(stage.start);
      final x1 = xFor(stage.end.add(const Duration(minutes: 1)));
      final path = Path()
        ..moveTo(x0, baseline)
        ..lineTo(x0, y)
        ..lineTo(x1, y)
        ..lineTo(x1, baseline)
        ..close();
      final color = _colorFor(stage.kind);
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.30),
              color.withValues(alpha: 0.02),
            ],
          ).createShader(Rect.fromLTRB(x0, padT, x1, baseline)),
      );
      canvas.drawLine(
        Offset(x0, y),
        Offset(x1, y),
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  Color _colorFor(SleepStageKind kind) => switch (kind) {
    SleepStageKind.awake => HelioColors.sleepAwake,
    SleepStageKind.rem => HelioColors.sleepRem,
    SleepStageKind.light => HelioColors.sleepLight,
    SleepStageKind.deep => HelioColors.sleepDeep,
    SleepStageKind.unknown => HelioColors.textMuted,
  };

  void _paintText(Canvas canvas, String text, Offset at, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant SleepHypnogramPainter oldDelegate) =>
      oldDelegate.stages != stages || oldDelegate.t0 != t0;
}
