import 'package:flutter/material.dart';

abstract final class HelioColors {
  static const canvas = Color(0xFF000000);
  static const surface = Color(0xFF141414);
  static const surfaceElevated = Color(0xFF1C1C1E);
  static const ringTrack = Color(0xFF2C2C2E);
  static const border = Color(0x1AFFFFFF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8E8E93);
  static const textMuted = Color(0xFF636366);
  static const recoveryLow = Color(0xFFFF453A);
  static const recoveryMid = Color(0xFFFFD60A);
  static const recoveryHigh = Color(0xFF30D158);
  static const sleepBlue = Color(0xFF0A84FF);
  static const strainBlue = Color(0xFF64D2FF);
  static const stressLow = Color(0xFF64D2FF);
  static const outlookGold = Color(0xFFC9A227);
  static const optimalGreen = Color(0xFF30D158);
  static const syncActive = Color(0xFF0A84FF);
  static const syncError = Color(0xFFFF453A);
  static const sleepDeep = Color(0xFF5856D6);
  static const sleepRem = Color(0xFF0A84FF);
  static const sleepLight = Color(0xFF64D2FF);
}

Color recoveryColorFor(int? score) {
  if (score == null) return HelioColors.textMuted;
  if (score <= 33) return HelioColors.recoveryLow;
  if (score <= 66) return HelioColors.recoveryMid;
  return HelioColors.recoveryHigh;
}
