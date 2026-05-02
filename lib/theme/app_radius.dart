// lib/theme/app_radius.dart
import 'package:flutter/material.dart';

/// Corner radius tokens.
class AppRadius {
  AppRadius._();
  static const double chip     = 8;
  static const double input    = 10;
  static const double listRow  = 12;
  static const double card     = 14;
  static const double modal    = 16;
  static const double pill     = 999;

  static const BorderRadius rChip    = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius rInput   = BorderRadius.all(Radius.circular(input));
  static const BorderRadius rListRow = BorderRadius.all(Radius.circular(listRow));
  static const BorderRadius rCard    = BorderRadius.all(Radius.circular(card));
  static const BorderRadius rModal   = BorderRadius.all(Radius.circular(modal));
  static const BorderRadius rPill    = BorderRadius.all(Radius.circular(pill));
}
