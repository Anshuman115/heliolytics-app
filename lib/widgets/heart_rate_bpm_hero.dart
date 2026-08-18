import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/utils/formatters.dart';

class HeartRateBpmHero extends StatelessWidget {
  final int? bpm;
  final String label;
  final DateTime? at;
  final bool isLive;

  const HeartRateBpmHero({
    super.key,
    required this.bpm,
    required this.label,
    this.at,
    required this.isLive,
  });

  @override
  Widget build(BuildContext context) {
    final status = label.replaceAll(' BPM', '');
    final value = bpm?.toString() ?? '—';
    return Semantics(
      label: bpm == null
          ? 'Heart rate data unavailable, $status'
          : '$bpm beats per minute, $status',
      button: true,
      child: SizedBox(
        height: 190,
        child: CustomPaint(
          painter: const _HeartRateGridPainter(),
          child: Padding(
            padding: const EdgeInsets.all(HelioSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HEART RATE', style: HelioTypography.sectionTitle),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      isLive ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isLive
                          ? HelioColors.recoveryLow
                          : HelioColors.textMuted,
                    ),
                    const SizedBox(width: HelioSpacing.sm),
                    Text(status, style: HelioTypography.capsLabel),
                  ],
                ),
                const SizedBox(height: HelioSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: HelioTypography.scoreMedium.copyWith(fontSize: 44),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 6),
                      child: Text('BPM', style: HelioTypography.capsLabel),
                    ),
                  ],
                ),
                if (at != null)
                  Text(
                    isLive ? 'NOW' : formatChartTime(at!).toUpperCase(),
                    style: HelioTypography.capsLabel.copyWith(fontSize: 9),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartRateGridPainter extends CustomPainter {
  const _HeartRateGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeartRateGridPainter oldDelegate) => false;
}
