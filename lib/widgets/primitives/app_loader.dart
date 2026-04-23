// lib/widgets/primitives/app_loader.dart
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../theme/app_colors.dart';

/// Theme-aligned EasyLoading configuration. Call [configure] once from main().
class AppLoader {
  AppLoader._();

  static void configure() {
    EasyLoading.instance
      ..loadingStyle = EasyLoadingStyle.custom
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..maskType = EasyLoadingMaskType.custom
      ..backgroundColor = AppColors.surfaceContainerHigh
      ..indicatorColor = AppColors.primary
      ..textColor = AppColors.onSurface
      ..maskColor = const Color(0x66000000)
      ..boxShadow = const [] // no extra shadow; card uses its own
      ..userInteractions = false
      ..dismissOnTap = false
      ..radius = 14
      ..fontSize = 13;
  }

  /// Inline loader for use inside a screen.
  static Widget inline({double size = 28}) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}
