// lib/theme/app_gradients.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Gradients — reserved for hero/identity moments (drawer header, balance
/// hero card, featured offer card). Not for ambient surfaces.
class AppGradients {
  AppGradients._();

  /// Signature 3-stop: navy → darker navy → teal.
  static const LinearGradient signature = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary,           // #10278C
      AppColors.primaryContainer,  // #0F4C75
      AppColors.secondary,         // #3282B8
    ],
  );

  /// 2-stop variant used when the 3rd stop would be too bright (e.g. on
  /// smaller surfaces like drawer headers).
  static const LinearGradient signatureCompact = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary,
      AppColors.primaryContainer,
    ],
  );
}
