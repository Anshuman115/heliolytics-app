import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';

class HelioSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const HelioSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(HelioSpacing.lg),
      decoration: BoxDecoration(
        color: HelioColors.surface,
        borderRadius: BorderRadius.circular(HelioRadii.card),
        border: Border.all(color: HelioColors.border),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HelioRadii.card),
        child: body,
      ),
    );
  }
}
