// test/widgets/primitives/app_badge_test.dart
import 'package:aultra_paints_mobile/theme/app_theme.dart';
import 'package:aultra_paints_mobile/widgets/primitives/app_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(theme: AppTheme.light(), home: Scaffold(body: w));

  testWidgets('AppBadge renders label and tone', (tester) async {
    await tester.pumpWidget(wrap(const AppBadge(label: 'SHIPPED', tone: AppBadgeTone.success)));
    expect(find.text('SHIPPED'), findsOneWidget);
  });
}
