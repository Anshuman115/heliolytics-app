import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/models/sleep_stage.dart';

class SleepTimelineBar extends StatelessWidget {
  const SleepTimelineBar({
    super.key,
    required this.stages,
    required this.totalMinutes,
    required this.awakeOnly,
  });

  final List<SleepStagePoint> stages;
  final int totalMinutes;
  final bool awakeOnly;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: CustomPaint(
      painter: _SleepTimelinePainter(
        stages: stages,
        totalMinutes: totalMinutes,
        awakeOnly: awakeOnly,
      ),
    ),
  );
}

class _SleepTimelinePainter extends CustomPainter {
  const _SleepTimelinePainter({
    required this.stages,
    required this.totalMinutes,
    required this.awakeOnly,
  });

  final List<SleepStagePoint> stages;
  final int totalMinutes;
  final bool awakeOnly;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    canvas.drawRRect(track, Paint()..color = HelioColors.canvasBottom);
    _hatch(canvas, size);
    if (stages.isEmpty || totalMinutes <= 0) return;
    final start = stages
        .map((stage) => stage.start)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    for (final stage in stages) {
      if ((stage.kind == SleepStageKind.awake) != awakeOnly) continue;
      final left = _x(stage.start, start, size.width);
      final right = _x(stage.end, start, size.width);
      if (right <= left) continue;
      canvas.drawRect(
        Rect.fromLTRB(left, 0, right, size.height),
        Paint()
          ..color = awakeOnly ? HelioColors.sleepAwake : HelioColors.sleepBlue,
      );
    }
  }

  double _x(DateTime time, DateTime start, double width) =>
      ((time.difference(start).inSeconds / (totalMinutes * 60) * width).clamp(
        0,
        width,
      )).toDouble();

  void _hatch(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HelioColors.textMuted.withValues(alpha: 0.2)
      ..strokeWidth = 2;
    for (double x = -size.height; x < size.width + size.height; x += 10) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SleepTimelinePainter old) =>
      old.stages != stages ||
      old.totalMinutes != totalMinutes ||
      old.awakeOnly != awakeOnly;
}
