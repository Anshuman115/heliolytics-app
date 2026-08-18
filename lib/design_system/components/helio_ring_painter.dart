import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';

class HelioRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;

  const HelioRingPainter({
    required this.progress,
    required this.color,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke / 2;
    final track = Paint()
      ..color = HelioColors.ringTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    _drawReferenceMarkers(canvas, radius, center);

    if (progress <= 0) return;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  void _drawReferenceMarkers(Canvas canvas, double radius, Offset center) {
    final marker = Paint()
      ..color = HelioColors.textSecondary.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    for (final angle in [math.pi * 0.38, math.pi * 0.5, math.pi * 0.62]) {
      canvas.drawArc(bounds, angle, 0.025, false, marker);
    }
  }

  @override
  bool shouldRepaint(covariant HelioRingPainter old) =>
      old.progress != progress || old.color != color || old.stroke != stroke;
}
