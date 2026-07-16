import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heliolytics/constants/constants.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/utils/stress_zones.dart';
import 'package:heliolytics/widgets/stress/stress_zone_color.dart';

/// Semicircular stress gauge: a cool→warm arc with a needle at the reading.
class StressGauge extends StatelessWidget {
  /// Current stress, 0–[stressGaugeMax]. Null renders an empty gauge.
  final double? value;

  /// Timestamp of the reading, shown under the label.
  final String? atLabel;

  const StressGauge({super.key, required this.value, this.atLabel});

  static const _size = Size(260, 150);

  @override
  Widget build(BuildContext context) {
    final v = value;
    final zone = v == null ? null : stressZoneOf(v);

    return SizedBox(
      width: _size.width,
      height: _size.height + 34,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomPaint(size: _size, painter: _GaugePainter(value: v)),
          Positioned(top: 52, child: _readout(v, zone)),
          Positioned(left: 0, bottom: 6, child: _bound('0')),
          Positioned(
            right: 0,
            bottom: 6,
            child: _bound(stressGaugeMax.toStringAsFixed(0)),
          ),
        ],
      ),
    );
  }

  Widget _readout(double? v, StressZone? zone) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          v == null ? '—' : v.toStringAsFixed(0),
          style: HelioTypography.heroValue.copyWith(fontSize: 56),
        ),
        const SizedBox(height: 4),
        Text(
          zone == null ? 'NO DATA' : stressZoneLabel(zone),
          style: HelioTypography.heroUnit.copyWith(
            color: zone == null ? HelioColors.textMuted : stressZoneColor(zone),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (atLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            atLabel!,
            style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _bound(String text) => Text(
        text,
        style: HelioTypography.bodyMuted.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value});

  final double? value;

  static const _stroke = 12.0;
  static const _start = math.pi; // 180° — left end
  static const _sweep = math.pi; // half circle

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _stroke / 2,
      _stroke / 2,
      size.width - _stroke,
      (size.height - _stroke / 2) * 2,
    );

    canvas.drawArc(
      rect,
      _start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: _start,
          endAngle: _start + _sweep,
          colors: stressGaugeColors,
          stops: [0.0, 0.55, 1.0],
          transform: GradientRotation(_start),
        ).createShader(rect),
    );

    final v = value;
    if (v == null) return;

    // Needle at the reading, clamped so it can never leave the arc.
    final frac = (v / stressGaugeMax).clamp(0.0, 1.0);
    final angle = _start + _sweep * frac;
    final centre = Offset(rect.center.dx, rect.top + rect.height / 2);
    final radius = rect.width / 2;

    final inner = centre + Offset(math.cos(angle), math.sin(angle)) * (radius - _stroke);
    final outer = centre + Offset(math.cos(angle), math.sin(angle)) * (radius + 2);

    canvas.drawLine(
      inner,
      outer,
      Paint()
        ..color = HelioColors.textPrimary
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value;
}
