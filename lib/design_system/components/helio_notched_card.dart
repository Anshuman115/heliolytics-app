import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/components/helio_surface_card.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';

class HelioNotchedCard extends StatelessWidget {
  const HelioNotchedCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? HelioColors.canvas.withValues(alpha: 0.42);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -7,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(width: 16, height: 16, color: cardColor),
            ),
          ),
        ),
        HelioSurfaceCard(color: cardColor, padding: padding, child: child),
      ],
    );
  }
}
