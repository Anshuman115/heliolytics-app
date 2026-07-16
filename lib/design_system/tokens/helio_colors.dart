import 'package:flutter/material.dart';

abstract final class HelioColors {
  // Backgrounds — charcoal, not pure black
  static const canvas = Color(0xFF1A1A1E);
  static const surface = Color(0xFF252529);
  static const surfaceElevated = Color(0xFF2C2C30);
  static const ringTrack = Color(0xFF3A3A3E);
  static const border = Color(0x1FFFFFFF);

  // Canvas gradient — subtle teal-charcoal at top fading to near-black,
  // a lit ambient backdrop (never a flat fill).
  static const canvasTop = Color(0xFF233039);
  static const canvasMid = Color(0xFF181A1F);
  static const canvasBottom = Color(0xFF101013);
  // Soft accent bloom painted near the top of every screen so the header
  // floats on lit glass rather than flat black.
  static const canvasGlow = Color(0xFF3DA9C9);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8E8E93);
  static const textMuted = Color(0xFF636366);

  // Recovery / readiness
  static const recoveryLow = Color(0xFFFF453A);
  static const recoveryMid = Color(0xFFFFD60A);
  static const recoveryHigh = Color(0xFF30D158);

  // Sleep
  static const sleepBlue = Color(0xFF0A84FF);
  static const sleepDeep = Color(0xFF5E5CE6);
  static const sleepRem = Color(0xFF64D2FF);
  static const sleepLight = Color(0xFF30D158);
  static const sleepAwake = Color(0xFF636366);

  // Strain / activity
  static const strainBlue = Color(0xFF64D2FF);

  // Stress
  static const stressLow = Color(0xFF64D2FF);

  // Misc
  static const outlookGold = Color(0xFFC9A227);
  static const optimalGreen = Color(0xFF30D158);

  // Health-monitor verdict chips: in-range vs worth-a-look.
  static const tierOptimal = Color(0xFF16C784);
  static const tierCaution = Color(0xFFFF9F0A);
  static const syncActive = Color(0xFF0A84FF);
  static const syncError = Color(0xFFFF453A);

  // HR Zones (zone palette, zone 0 = rest → zone 5 = max)
  static const hrZone0 = Color(0xFF636366);
  static const hrZone1 = Color(0xFF30D158);
  static const hrZone2 = Color(0xFF64D2FF);
  static const hrZone3 = Color(0xFFFFD60A);
  static const hrZone4 = Color(0xFFFF9F0A);
  static const hrZone5 = Color(0xFFFF453A);
}

/// Performance tiers: Poor (red) · Sufficient (yellow) · Optimal (green).
/// Used by sleep-performance bars and their legend.
Color qualityTierColor(num pct) {
  if (pct < 50) return HelioColors.recoveryLow;
  if (pct < 75) return HelioColors.recoveryMid;
  return HelioColors.optimalGreen;
}

Color recoveryColorFor(int? score) {
  if (score == null) return HelioColors.textMuted;
  if (score <= 33) return HelioColors.recoveryLow;
  if (score <= 66) return HelioColors.recoveryMid;
  return HelioColors.recoveryHigh;
}

Color hrZoneColor(int zone) => switch (zone) {
      0 => HelioColors.hrZone0,
      1 => HelioColors.hrZone1,
      2 => HelioColors.hrZone2,
      3 => HelioColors.hrZone3,
      4 => HelioColors.hrZone4,
      _ => HelioColors.hrZone5,
    };
