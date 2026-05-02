// lib/theme/app_shadows.dart
import 'package:flutter/material.dart';

/// Elevation / shadow tokens. Access via `context.shadows` (below) or
/// reference `AppShadows.card` directly in primitives.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x1210278C), // rgba(16,39,140,0.07)
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> cardHover = [
    BoxShadow(
      color: Color(0x1F10278C), // rgba(16,39,140,0.12)
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> featured = [
    BoxShadow(
      color: Color(0x2E10278C), // rgba(16,39,140,0.18)
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> form = [
    BoxShadow(
      color: Color(0x1410278C), // rgba(16,39,140,0.08)
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> scrim = [
    BoxShadow(
      color: Color(0x66000000), // rgba(0,0,0,0.4)
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  ];
}
