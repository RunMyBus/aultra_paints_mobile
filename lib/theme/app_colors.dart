import 'package:flutter/material.dart';

/// Single source of truth for theme seed and any brand-fixed accents.
///
/// The primary seed is the Aultra brand slate blue used in the legacy
/// palette (`lib/utility/Colors.dart` -> `appColor`, `appThemeColor`).
/// All Material 3 colour roles are derived from it via
/// `ColorScheme.fromSeed`.
class AppColors {
  AppColors._();

  static const Color seed = Color(0xFF2C3E50);
}
