import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioWordmark extends StatelessWidget {
  const HelioWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        'HELIOLYTICS',
        textAlign: TextAlign.center,
        style: HelioTypography.sectionTitle.copyWith(
          color: HelioColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w300,
          letterSpacing: 6,
        ),
      ),
    );
  }
}
