// lib/widgets/primitives/app_card.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

enum AppCardEmphasis { normal, hover, featured, form }

/// Modern-card surface: white, radius-14, soft shadow. Use [emphasis] to
/// pick the shadow weight. Avoid nesting AppCards — it muddies elevation.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.emphasis = AppCardEmphasis.normal,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final AppCardEmphasis emphasis;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shadow = switch (emphasis) {
      AppCardEmphasis.normal   => AppShadows.card,
      AppCardEmphasis.hover    => AppShadows.cardHover,
      AppCardEmphasis.featured => AppShadows.featured,
      AppCardEmphasis.form     => AppShadows.form,
    };

    final surface = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: AppRadius.rCard,
        boxShadow: shadow,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return surface;
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.rCard,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: surface),
    );
  }
}
