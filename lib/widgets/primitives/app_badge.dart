// lib/widgets/primitives/app_badge.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

enum AppBadgeTone { info, success, error, neutral }

/// Pill badge for status/role/cashback. Uppercase label, tight padding,
/// tone-driven color pair from [AppSemantics].
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.info,
  });

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AppBadgeTone.info    => (AppColors.infoBg,    AppColors.onInfo),
      AppBadgeTone.success => (AppColors.successBg, AppColors.onSuccess),
      AppBadgeTone.error   => (AppColors.errorBg,   AppColors.onError),
      AppBadgeTone.neutral => (AppColors.outline,   AppColors.onSurface),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.rPill),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: fg, letterSpacing: 0.6),
      ),
    );
  }
}
