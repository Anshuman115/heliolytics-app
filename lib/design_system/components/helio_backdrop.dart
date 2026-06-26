import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';

/// Ambient backdrop: a vertical teal-charcoal gradient with a
/// soft accent bloom near the top where the header + hero rings sit. Wrap any
/// screen body in this instead of relying on a flat scaffold colour.
class HelioBackdrop extends StatelessWidget {
  final Widget child;

  const HelioBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base vertical gradient.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  HelioColors.canvasTop,
                  HelioColors.canvasMid,
                  HelioColors.canvasBottom,
                ],
                stops: [0.0, 0.34, 1.0],
              ),
            ),
          ),
        ),
        // Ambient bloom behind the header / hero area.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 420,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1.1),
                radius: 1.2,
                colors: [
                  HelioColors.canvasGlow.withValues(alpha: 0.20),
                  HelioColors.canvasGlow.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
