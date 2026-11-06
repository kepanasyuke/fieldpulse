import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF1F6FEB);

  static ThemeData light({TargetPlatform? platform}) => _base(
    ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
    platform: platform,
  );

  static ThemeData dark({TargetPlatform? platform}) => _base(
    ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
    platform: platform,
  );

  static ThemeData _base(ColorScheme scheme, {TargetPlatform? platform}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      platform: platform,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: platform == TargetPlatform.iOS,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
