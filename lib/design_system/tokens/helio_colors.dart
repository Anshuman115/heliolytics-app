import 'package:flutter/material.dart';

abstract final class HelioColors {
  // Backgrounds — WHOOP charcoal, not pure black
  static const canvas = Color(0xFF1A1A1E);
  static const surface = Color(0xFF252529);
  static const surfaceElevated = Color(0xFF2C2C30);
  static const ringTrack = Color(0xFF3A3A3E);
  static const border = Color(0x1FFFFFFF);

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
  static const syncActive = Color(0xFF0A84FF);
  static const syncError = Color(0xFFFF453A);

  // HR Zones (WHOOP palette, zone 0 = rest → zone 5 = max)
  static const hrZone0 = Color(0xFF636366);
  static const hrZone1 = Color(0xFF30D158);
  static const hrZone2 = Color(0xFF64D2FF);
  static const hrZone3 = Color(0xFFFFD60A);
  static const hrZone4 = Color(0xFFFF9F0A);
  static const hrZone5 = Color(0xFFFF453A);
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
