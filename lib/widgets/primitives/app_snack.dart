// lib/widgets/primitives/app_snack.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum AppSnackTone { neutral, success, error, info }

class AppSnack {
  AppSnack._();

  static void show(BuildContext context, String message, {AppSnackTone tone = AppSnackTone.neutral}) {
    final (bg, fg) = switch (tone) {
      AppSnackTone.neutral => (AppColors.onSurface, Colors.white),
      AppSnackTone.success => (AppColors.onSuccess, Colors.white),
      AppSnackTone.error   => (AppColors.onError,   Colors.white),
      AppSnackTone.info    => (AppColors.onInfo,    Colors.white),
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        content: Text(message, style: TextStyle(color: fg)),
      ),
    );
  }
}
