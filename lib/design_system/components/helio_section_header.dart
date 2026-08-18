import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

class HelioSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final String? trailingText;

  const HelioSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final tail =
        trailing ??
        (trailingText != null
            ? Text(trailingText!, style: HelioTypography.capsLabel)
            : null);
    return Padding(
      padding: const EdgeInsets.only(bottom: HelioSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: HelioTypography.sectionTitle,
            ),
          ),
          if (tail != null) tail,
        ],
      ),
    );
  }
}
