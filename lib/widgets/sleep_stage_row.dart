import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/utils/formatters.dart';

/// Single sleep stage row:
/// ○  STAGE NAME  ···  X%  duration
/// ████████████░░░░░░░ (progress bar)
class SleepStageRow extends StatelessWidget {
  final String label;
  final Color color;
  final int minutes;
  final int totalMinutes;

  const SleepStageRow({
    super.key,
    required this.label,
    required this.color,
    required this.minutes,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalMinutes > 0
        ? (minutes / totalMinutes).clamp(0.0, 1.0)
        : 0.0;
    final pctStr = totalMinutes > 0 ? '${(pct * 100).round()}%' : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HelioSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Stage colour dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              const SizedBox(width: HelioSpacing.md),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HelioTypography.capsLabel.copyWith(fontSize: 11),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  pctStr,
                  textAlign: TextAlign.end,
                  style: HelioTypography.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(width: HelioSpacing.sm),
              Text(
                formatSleepMins(minutes),
                style: HelioTypography.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HelioColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: HelioSpacing.xs + 2),
          SizedBox(
            height: 18,
            child: CustomPaint(
              painter: _StageTrackPainter(progress: pct, color: color),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageTrackPainter extends CustomPainter {
  const _StageTrackPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const height = 14.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, (size.height - height) / 2, size.width, height),
      const Radius.circular(3),
    );
    canvas.drawRRect(rect, Paint()..color = HelioColors.canvasBottom);

    canvas.save();
    canvas.clipRRect(rect);
    final hatch = Paint()
      ..color = HelioColors.textMuted.withValues(alpha: 0.18)
      ..strokeWidth = 2;
    for (double x = -size.height; x < size.width + size.height; x += 8) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        hatch,
      );
    }
    final fillWidth = size.width * progress;
    canvas.drawRect(
      Rect.fromLTWH(0, (size.height - height) / 2, fillWidth, height),
      Paint()..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StageTrackPainter old) =>
      old.progress != progress || old.color != color;
}
