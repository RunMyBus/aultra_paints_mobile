// lib/widgets/primitives/app_app_bar.dart
import 'package:flutter/material.dart';

/// Themed AppBar. Solid primary background, centered title.
///
/// Use [leading]/[trailing] with [AppAppBarAction] to get bordered
/// square icon buttons matching the mockup (28x28 with 1px white 30%
/// border). If [leading] is null and [automaticallyImplyLeading] is true,
/// Flutter's default back/menu appears (styled by theme).
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final AppAppBarAction? leading;
  final AppAppBarAction? trailing;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final appBarTheme = Theme.of(context).appBarTheme;
    return AppBar(
      backgroundColor: appBarTheme.backgroundColor,
      title: Text(title),
      leading: leading,
      actions: trailing == null ? null : [trailing!, const SizedBox(width: 8)],
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}

/// Bordered square icon button used inside [AppAppBar].
class AppAppBarAction extends StatelessWidget {
  const AppAppBarAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.bordered = true,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: bordered ? Border.all(color: onPrimary.withOpacity(0.3)) : null,
          ),
          child: Icon(icon, size: 16, color: onPrimary),
        ),
      ),
    );
  }
}
