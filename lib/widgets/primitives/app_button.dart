// lib/widgets/primitives/app_button.dart
import 'package:flutter/material.dart';

enum _AppButtonVariant { filled, outlined, text }

/// Themed button. Use factories [filled], [outlined], or [text].
/// Pass [loading] = true to show an inline spinner and disable taps.
class AppButton extends StatelessWidget {
  const AppButton._({
    required this.label,
    required this.onPressed,
    required this.variant,
    this.icon,
    this.fullWidth = false,
    this.loading = false,
  });

  factory AppButton.filled({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool fullWidth = false,
    bool loading = false,
  }) =>
      AppButton._(
        label: label,
        onPressed: onPressed,
        variant: _AppButtonVariant.filled,
        icon: icon,
        fullWidth: fullWidth,
        loading: loading,
      );

  factory AppButton.outlined({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool fullWidth = false,
    bool loading = false,
  }) =>
      AppButton._(
        label: label,
        onPressed: onPressed,
        variant: _AppButtonVariant.outlined,
        icon: icon,
        fullWidth: fullWidth,
        loading: loading,
      );

  factory AppButton.text({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool loading = false,
  }) =>
      AppButton._(
        label: label,
        onPressed: onPressed,
        variant: _AppButtonVariant.text,
        icon: icon,
        fullWidth: false,
        loading: loading,
      );

  final String label;
  final VoidCallback onPressed;
  final _AppButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final effOnPressed = loading ? null : onPressed;

    Widget content;
    if (loading) {
      content = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      );
    } else {
      content = Text(label);
    }

    final child = fullWidth
        ? SizedBox(width: double.infinity, child: Center(child: content))
        : content;

    return switch (variant) {
      _AppButtonVariant.filled   => ElevatedButton(onPressed: effOnPressed, child: child),
      _AppButtonVariant.outlined => OutlinedButton(onPressed: effOnPressed, child: child),
      _AppButtonVariant.text     => TextButton(onPressed: effOnPressed, child: child),
    };
  }
}
