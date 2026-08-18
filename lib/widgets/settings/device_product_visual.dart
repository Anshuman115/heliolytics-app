import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';

class DeviceProductVisual extends StatelessWidget {
  const DeviceProductVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HelioSpacing.sm),
      child: SizedBox(
        width: double.infinity,
        height: 280,
        child: Image.asset(
          'assets/images/helio_strap.png',
          fit: BoxFit.contain,
          semanticLabel: 'Helio fitness strap',
        ),
      ),
    );
  }
}
