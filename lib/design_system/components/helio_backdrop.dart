import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';

/// Shared blue-charcoal backdrop for every app route.
class HelioBackdrop extends StatelessWidget {
  final Widget child;

  const HelioBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HelioColors.canvasTop,
            HelioColors.canvasMid,
            HelioColors.canvasBottom,
          ],
          stops: [0, 0.32, 1],
        ),
      ),
      child: child,
    );
  }
}
