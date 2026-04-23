// lib/widgets/primitives/app_dialog.dart
import 'package:flutter/material.dart';
import 'app_button.dart';

class AppDialogAction {
  AppDialogAction({required this.label, required this.onPressed, this.primary = false});
  final String label;
  final VoidCallback onPressed;
  final bool primary;
}

/// Show a themed dialog. Returns the result of the dialog.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required Widget body,
  List<AppDialogAction> actions = const [],
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogCtx) => AlertDialog(
      title: Text(title),
      content: body,
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: actions.map((a) {
        void cb() {
          Navigator.of(dialogCtx).pop();
          a.onPressed();
        }
        return a.primary
            ? AppButton.filled(label: a.label, onPressed: cb)
            : AppButton.text(label: a.label, onPressed: cb);
      }).toList(),
    ),
  );
}
