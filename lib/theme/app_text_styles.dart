// lib/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography scale for the app.
///
/// Built on the bundled Plus Jakarta Sans variable font (registered as the
/// 'PlusJakartaSans' family in pubspec.yaml). Avoids `google_fonts` runtime
/// resolution because that package expects per-weight static TTFs.
class AppTextStyles {
  AppTextStyles._();

  static const String _family = 'PlusJakartaSans';

  /// Returns a Material 3 [TextTheme] anchored to Plus Jakarta Sans.
  /// Sizes mapped to our design scale (see spec §5.2).
  static TextTheme textTheme() {
    return TextTheme(
      // Display — points balance, hero numerals
      displayLarge:  _t(size: 32, weight: FontWeight.w700, tracking: -0.5),
      displayMedium: _t(size: 28, weight: FontWeight.w700, tracking: -0.4),
      displaySmall:  _t(size: 26, weight: FontWeight.w700, tracking: -0.4),

      // Titles
      titleLarge:    _t(size: 20, weight: FontWeight.w700, tracking: -0.3),
      titleMedium:   _t(size: 16, weight: FontWeight.w700),
      titleSmall:    _t(size: 14, weight: FontWeight.w600),

      // Body
      bodyLarge:     _t(size: 14, weight: FontWeight.w500),
      bodyMedium:    _t(size: 13, weight: FontWeight.w500),
      bodySmall:     _t(size: 11, weight: FontWeight.w500),

      // Labels
      labelLarge:    _t(size: 13, weight: FontWeight.w700, tracking: 0.2),
      labelMedium:   _t(size: 11, weight: FontWeight.w600, tracking: 0.2),
      labelSmall:    _t(size: 10, weight: FontWeight.w600, tracking: 0.6),
    ).apply(
      bodyColor:    AppColors.onSurface,
      displayColor: AppColors.onSurface,
    );
  }

  /// Overline: uppercase section labels (e.g. "POINTS BALANCE")
  static TextStyle overline({Color? color}) => _t(
        size: 10,
        weight: FontWeight.w600,
        tracking: 0.6,
        color: color ?? AppColors.onSurfaceVariant,
      ).copyWith(height: 1.2);

  /// Button label (filled/outlined/text)
  static TextStyle button({Color? color}) => _t(
        size: 13,
        weight: FontWeight.w700,
        tracking: 0.2,
        color: color,
      );

  static TextStyle _t({
    required double size,
    required FontWeight weight,
    double tracking = 0,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: _family,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: tracking,
        color: color,
      );
}
