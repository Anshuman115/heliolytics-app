import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_ring_painter.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

enum HelioRingSize { heroXl, hero, triple, standard }

class HelioScoreRing extends StatelessWidget {
  final double? progress;
  final String label;
  final String value;
  final Color color;
  final HelioRingSize size;
  final String? eyebrow;
  final bool showScoreBars;
  final bool showChevron;
  final VoidCallback? onTap;

  const HelioScoreRing({
    super.key,
    required this.progress,
    required this.label,
    required this.value,
    required this.color,
    this.size = HelioRingSize.triple,
    this.eyebrow,
    this.showScoreBars = false,
    this.showChevron = true,
    this.onTap,
  });

  double get _diameter => switch (size) {
    HelioRingSize.heroXl => 250,
    HelioRingSize.hero => 228,
    HelioRingSize.triple => 86,
    HelioRingSize.standard => 90,
  };

  double get _stroke => switch (size) {
    HelioRingSize.heroXl => 16,
    HelioRingSize.hero => 15,
    HelioRingSize.triple => 6,
    HelioRingSize.standard => 7,
  };

  double get _valueSize => switch (size) {
    HelioRingSize.heroXl => 72,
    HelioRingSize.hero => 64,
    HelioRingSize.triple => 24,
    HelioRingSize.standard => 22,
  };

  @override
  Widget build(BuildContext context) {
    final hero = size == HelioRingSize.heroXl || size == HelioRingSize.hero;
    final ring = SizedBox(
      width: _diameter,
      height: _diameter,
      child: CustomPaint(
        painter: HelioRingPainter(
          progress: (progress ?? 0).clamp(0.0, 1.0),
          color: color,
          stroke: _stroke,
        ),
        child: Center(
          child: hero
              ? _heroCenter()
              : Text(
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
            fontSize: size == HelioRingSize.triple ? 9 : 10,
            color: HelioColors.textSecondary,
            letterSpacing: 0,
          ),
        ),
        if (showChevron && !hero) ...[
          const SizedBox(width: 2),
          const Icon(
            Icons.chevron_right,
            size: 14,
            color: HelioColors.textSecondary,
          ),
        ],
      ],
    );

    final content = SizedBox(
      width: _diameter + 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ring,
          if (!hero) ...[const SizedBox(height: 12), labelRow],
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  Widget _heroCenter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!,
            style: HelioTypography.capsLabel.copyWith(
              color: HelioColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(value, style: HelioTypography.heroValue),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: HelioTypography.heroUnit),
        if (showScoreBars) ...[const SizedBox(height: 10), _scoreBars()],
      ],
    );
  }

  Widget _scoreBars() {
    final score = double.tryParse(value.replaceAll('%', '')) ?? 0;
    final active = score >= 75
        ? HelioColors.optimalGreen
        : score >= 50
        ? HelioColors.recoveryMid
        : HelioColors.recoveryLow;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _scoreBar(HelioColors.ringTrack),
        const SizedBox(width: 5),
        _scoreBar(active),
        const SizedBox(width: 5),
        _scoreBar(HelioColors.ringTrack),
      ],
    );
  }

  Widget _scoreBar(Color color) => Container(
    width: 16,
    height: 4,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
