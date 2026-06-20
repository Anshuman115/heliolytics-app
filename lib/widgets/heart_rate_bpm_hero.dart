import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';
import 'package:heliolytics/utils/formatters.dart';

class HeartRateBpmHero extends StatefulWidget {
  final int bpm;
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
  State<HeartRateBpmHero> createState() => _HeartRateBpmHeroState();
}

class _HeartRateBpmHeroState extends State<HeartRateBpmHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isLive) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant HeartRateBpmHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLive && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.isLive && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: HelioSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  HelioColors.sleepBlue.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HelioColors.surface,
              border: Border.all(
                color: widget.isLive ? HelioColors.recoveryLow : HelioColors.border,
                width: widget.isLive ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isLive)
                      FadeTransition(
                        opacity: Tween(begin: 0.35, end: 1.0).animate(_pulse),
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: HelioColors.recoveryLow,
                          ),
                        ),
                      )
                    else
                      const Icon(Icons.favorite, size: 12, color: HelioColors.recoveryLow),
                    const SizedBox(width: 4),
                    Text(
                      widget.label,
                      style: HelioTypography.capsLabel.copyWith(
                        fontSize: 9,
                        color: widget.isLive ? HelioColors.recoveryLow : null,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${widget.bpm}',
                  style: HelioTypography.scoreMedium.copyWith(fontSize: 40),
                ),
                if (widget.at != null)
                  Text(
                    widget.isLive ? 'now' : formatChartTime(widget.at!),
                    style: HelioTypography.capsLabel.copyWith(fontSize: 8),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
