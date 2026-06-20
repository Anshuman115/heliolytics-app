import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

enum HelioRingSize { hero, triple, standard }

class HelioScoreRing extends StatelessWidget {
  final double? progress;
  final String label;
  final String value;
  final Color color;
  final HelioRingSize size;
  final bool showChevron;
  final VoidCallback? onTap;

  const HelioScoreRing({
    super.key,
    required this.progress,
    required this.label,
    required this.value,
    required this.color,
    this.size = HelioRingSize.triple,
    this.showChevron = true,
    this.onTap,
  });

  double get _diameter => switch (size) {
        HelioRingSize.hero => 132,
        HelioRingSize.triple => 108,
        HelioRingSize.standard => 80,
      };

  double get _stroke => switch (size) {
        HelioRingSize.hero => 10,
        HelioRingSize.triple => 9,
        HelioRingSize.standard => 7,
      };

  double get _valueSize => switch (size) {
        HelioRingSize.hero => 36,
        HelioRingSize.triple => 28,
        HelioRingSize.standard => 22,
      };

  @override
  Widget build(BuildContext context) {
    final ring = SizedBox(
      width: _diameter,
      height: _diameter,
      child: CustomPaint(
        painter: _RingPainter(
          progress: (progress ?? 0).clamp(0.0, 1.0),
          color: color,
          stroke: _stroke,
        ),
        child: Center(
          child: Text(
            value,
            style: HelioTypography.scoreMedium.copyWith(
              fontSize: _valueSize,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );

    final labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: HelioTypography.capsLabel.copyWith(
            fontSize: 10,
            color: HelioColors.textSecondary,
            letterSpacing: 1.4,
          ),
        ),
        if (showChevron) ...[
          const SizedBox(width: 2),
          Icon(Icons.chevron_right, size: 14, color: HelioColors.textSecondary),
        ],
      ],
    );

    final content = SizedBox(
      width: _diameter + 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ring,
          const SizedBox(height: 10),
          labelRow,
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: content);
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;

  _RingPainter({required this.progress, required this.color, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke / 2;
    final track = Paint()
      ..color = HelioColors.ringTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
