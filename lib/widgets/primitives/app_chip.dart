// lib/widgets/primitives/app_chip.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// Filter / category chip. Pill shape. When [selected], uses primary fill.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme.labelMedium!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.rPill,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : AppColors.surfaceContainerHigh,
            borderRadius: AppRadius.rPill,
            border: selected ? null : Border.all(color: AppColors.outline),
          ),
          child: Text(
            label,
            style: text.copyWith(color: selected ? scheme.onPrimary : AppColors.onSurface),
          ),
        ),
      ),
    );
  }
}
