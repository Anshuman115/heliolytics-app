import 'package:flutter/material.dart';

abstract final class HelioColors {
  static const canvas = Color(0xFF10171B);
  static const surface = Color(0xFF282E32);
  static const surfaceElevated = Color(0xFF343A3E);
  static const ringTrack = Color(0xFF374047);
  static const border = Color(0x0FFFFFFF);

  static const canvasTop = Color(0xFF293740);
  static const canvasMid = Color(0xFF172126);
  static const canvasBottom = Color(0xFF0C1216);
  static const canvasGlow = Color(0xFF5B8298);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA4A9AD);
  static const textMuted = Color(0xFF70777C);

  // Recovery / readiness
  static const recoveryLow = Color(0xFFFF003C);
  static const recoveryMid = Color(0xFFFFD400);
  static const recoveryHigh = Color(0xFF00F000);

  // Sleep
  static const sleepBlue = Color(0xFF7FA8C2);
  static const sleepDeep = Color(0xFFE65BEA);
  static const sleepRem = Color(0xFFA94CE6);
  static const sleepLight = Color(0xFF9593E8);
  static const sleepAwake = Color(0xFFB6B7B9);

  // Strain / activity
  static const strainBlue = Color(0xFF009DE5);

  // Stress
  static const stressLow = Color(0xFF68B1E3);

  // Misc
  static const outlookGold = Color(0xFFC9A227);
  static const optimalGreen = Color(0xFF00E6A3);

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
