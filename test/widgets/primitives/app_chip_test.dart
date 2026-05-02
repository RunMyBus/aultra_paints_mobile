// test/widgets/primitives/app_chip_test.dart
import 'package:aultra_paints_mobile/theme/app_theme.dart';
import 'package:aultra_paints_mobile/widgets/primitives/app_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(theme: AppTheme.light(), home: Scaffold(body: w));

  testWidgets('AppChip unselected uses surface color', (tester) async {
    await tester.pumpWidget(wrap(AppChip(label: 'All', selected: false, onTap: () {})));
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('AppChip selected fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(AppChip(label: 'All', selected: true, onTap: () => tapped = true)));
    await tester.tap(find.text('All'));
    expect(tapped, isTrue);
  });
}
