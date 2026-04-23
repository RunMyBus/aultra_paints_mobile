// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Brand seed color — navy from aultrapaints.com.
/// Do not reference this elsewhere; use ColorScheme.fromSeed via AppTheme.
class AppColors {
  AppColors._();

  /// Seed for Material 3 ColorScheme.fromSeed.
  static const Color brandSeed = Color(0xFF10278C);

  // Portal palette (used for explicit overrides and gradients)
  static const Color primary         = Color(0xFF10278C);
  static const Color primaryContainer = Color(0xFF0F4C75);
  static const Color secondary       = Color(0xFF3282B8);
  static const Color tertiary        = Color(0xFFBBE1FA);

  // Neutrals
  static const Color surface               = Color(0xFFF5F3EF); // cream page bg
  static const Color surfaceContainerHigh  = Color(0xFFFFFFFF); // card bg
  static const Color outline               = Color(0xFFE2E8F0);
  static const Color outlineVariant        = Color(0xFFCBD5E1);
  static const Color onSurface             = Color(0xFF1E293B); // ink
  static const Color onSurfaceVariant      = Color(0xFF64748B); // muted ink

  // Semantic pairs (bg / on)
  static const Color successBg  = Color(0xFFD1FAE5);
  static const Color onSuccess  = Color(0xFF065F46);
  static const Color errorBg    = Color(0xFFFEE2E2);
  static const Color onError    = Color(0xFFB91C1C);
  static const Color infoBg     = Color(0xFFE0F2FE);
  static const Color onInfo     = Color(0xFF0F4C75);

  // Dark chrome (QR scanner)
  static const Color scannerBg       = Color(0xFF0A1128);
  static const Color scannerAccent   = Color(0xFF7CD4FD);
}

/// Semantic color tokens not covered by Material 3's ColorScheme.
/// Access via `Theme.of(context).extension<AppSemantics>()!`.
@immutable
class AppSemantics extends ThemeExtension<AppSemantics> {
  const AppSemantics({
    required this.successBg,
    required this.onSuccess,
    required this.errorBg,
    required this.onError,
    required this.infoBg,
    required this.onInfo,
    required this.scannerBg,
    required this.scannerAccent,
  });

  final Color successBg;
  final Color onSuccess;
  final Color errorBg;
  final Color onError;
  final Color infoBg;
  final Color onInfo;
  final Color scannerBg;
  final Color scannerAccent;

  static const AppSemantics light = AppSemantics(
    successBg:      AppColors.successBg,
    onSuccess:      AppColors.onSuccess,
    errorBg:        AppColors.errorBg,
    onError:        AppColors.onError,
    infoBg:         AppColors.infoBg,
    onInfo:         AppColors.onInfo,
    scannerBg:      AppColors.scannerBg,
    scannerAccent:  AppColors.scannerAccent,
  );

  @override
  AppSemantics copyWith({
    Color? successBg, Color? onSuccess,
    Color? errorBg, Color? onError,
    Color? infoBg, Color? onInfo,
    Color? scannerBg, Color? scannerAccent,
  }) => AppSemantics(
        successBg:     successBg     ?? this.successBg,
        onSuccess:     onSuccess     ?? this.onSuccess,
        errorBg:       errorBg       ?? this.errorBg,
        onError:       onError       ?? this.onError,
        infoBg:        infoBg        ?? this.infoBg,
        onInfo:        onInfo        ?? this.onInfo,
        scannerBg:     scannerBg     ?? this.scannerBg,
        scannerAccent: scannerAccent ?? this.scannerAccent,
      );

  @override
  AppSemantics lerp(ThemeExtension<AppSemantics>? other, double t) {
    if (other is! AppSemantics) return this;
    return AppSemantics(
      successBg:     Color.lerp(successBg,     other.successBg,     t)!,
      onSuccess:     Color.lerp(onSuccess,     other.onSuccess,     t)!,
      errorBg:       Color.lerp(errorBg,       other.errorBg,       t)!,
      onError:       Color.lerp(onError,       other.onError,       t)!,
      infoBg:        Color.lerp(infoBg,        other.infoBg,        t)!,
      onInfo:        Color.lerp(onInfo,        other.onInfo,        t)!,
      scannerBg:     Color.lerp(scannerBg,     other.scannerBg,     t)!,
      scannerAccent: Color.lerp(scannerAccent, other.scannerAccent, t)!,
    );
  }
}

/// Convenience accessor: `context.semantic.successBg`
extension AppSemanticsOnBuildContext on BuildContext {
  AppSemantics get semantic => Theme.of(this).extension<AppSemantics>()!;
}
