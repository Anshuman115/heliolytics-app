import 'package:flutter/material.dart';

const _bg = Color(0xFF070A10);
const _card = Color(0xFF121820);
const _accent = Color(0xFF2DD4BF);
const _accent2 = Color(0xFF6366F1);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.dark(
    primary: _accent,
    secondary: _accent2,
    surface: _card,
    onSurface: const Color(0xFFE8EDF5),
    onSurfaceVariant: const Color(0xFF94A3B8),
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: _bg,
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      bodySmall: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF94A3B8)),
      labelSmall: TextStyle(fontSize: 11, letterSpacing: 0.2),
    ),
    cardTheme: CardThemeData(
      color: _card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0D1118),
      indicatorColor: _accent.withValues(alpha: 0.18),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.8)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
  );
}

LinearGradient headerGradient() => const LinearGradient(
      colors: [Color(0xFF0F766E), Color(0xFF4338CA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
