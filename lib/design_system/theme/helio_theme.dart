import 'package:flutter/material.dart';
import 'package:heliolytics/design_system/tokens/helio_colors.dart';
import 'package:heliolytics/design_system/tokens/helio_radii.dart';
import 'package:heliolytics/design_system/tokens/helio_typography.dart';

ThemeData buildHelioTheme() {
  const scheme = ColorScheme.dark(
    primary: HelioColors.sleepBlue,
    secondary: HelioColors.strainBlue,
    surface: HelioColors.surface,
    onSurface: HelioColors.textPrimary,
    onSurfaceVariant: HelioColors.textSecondary,
    error: HelioColors.recoveryLow,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: HelioColors.canvas,
    useMaterial3: true,
    textTheme: TextTheme(
      headlineSmall: HelioTypography.scoreMedium,
      titleMedium: HelioTypography.body.copyWith(fontWeight: FontWeight.w600),
      titleSmall: HelioTypography.bodyMuted,
      bodyMedium: HelioTypography.body,
      bodySmall: HelioTypography.bodyMuted,
      labelSmall: HelioTypography.capsLabel,
    ),
    cardTheme: CardThemeData(
      color: HelioColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HelioRadii.card),
        side: const BorderSide(color: HelioColors.border),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: HelioColors.canvas,
      elevation: 0,
      centerTitle: true,
      foregroundColor: HelioColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HelioColors.surfaceElevated,
      labelStyle: HelioTypography.capsLabel,
      hintStyle: HelioTypography.bodyMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HelioRadii.card),
        borderSide: const BorderSide(color: HelioColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HelioRadii.card),
        borderSide: const BorderSide(color: HelioColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HelioRadii.card),
        borderSide: const BorderSide(color: HelioColors.sleepBlue),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HelioColors.sleepBlue,
        foregroundColor: HelioColors.textPrimary,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HelioRadii.card),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HelioColors.textPrimary,
        side: const BorderSide(color: HelioColors.border),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HelioRadii.card),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: HelioColors.surface,
      indicatorColor: HelioColors.surfaceElevated,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return HelioTypography.navLabel.copyWith(
          color: selected ? HelioColors.textPrimary : HelioColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? HelioColors.textPrimary : HelioColors.textMuted,
          size: 22,
        );
      }),
    ),
    dividerColor: HelioColors.border,
    splashColor: HelioColors.textPrimary.withValues(alpha: 0.06),
    highlightColor: HelioColors.textPrimary.withValues(alpha: 0.04),
  );
}
