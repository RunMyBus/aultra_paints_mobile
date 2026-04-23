import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralised Material 3 theme. Screens continue to use existing
/// hard-coded colours from `lib/utility/Colors.dart`; per-screen colour
/// cleanup is deferred to Phase 1.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandSeed,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brandSeed,
          brightness: Brightness.dark,
        ),
      );
}
