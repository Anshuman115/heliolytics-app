import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';

abstract final class HelioTypography {
  static TextStyle get capsLabel => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: HelioColors.textSecondary,
      );

  static TextStyle get scoreLarge => const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: HelioColors.textPrimary,
        height: 1,
      );

  static TextStyle get scoreMedium => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: HelioColors.textPrimary,
        height: 1,
      );

  static TextStyle get body => const TextStyle(
        fontSize: 14,
        color: HelioColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyMuted => const TextStyle(
        fontSize: 13,
        color: HelioColors.textSecondary,
        height: 1.35,
      );

  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: HelioColors.textSecondary,
      );

  static TextStyle get navLabel => const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      );
}
