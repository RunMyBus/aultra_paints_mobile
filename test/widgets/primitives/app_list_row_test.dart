// test/widgets/primitives/app_list_row_test.dart
import 'package:aultra_paints_mobile/theme/app_theme.dart';
import 'package:aultra_paints_mobile/widgets/primitives/app_list_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(theme: AppTheme.light(), home: Scaffold(body: w));

  testWidgets('AppListRow renders title, subtitle, trailing', (tester) async {
    await tester.pumpWidget(wrap(const AppListRow(
      title: 'Rajesh Kumar',
      subtitle: '+91 98765 43210',
      trailing: Text('DEALER'),
    )));
    expect(find.text('Rajesh Kumar'), findsOneWidget);
    expect(find.text('+91 98765 43210'), findsOneWidget);
    expect(find.text('DEALER'), findsOneWidget);
  });

  testWidgets('AppListRow fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(AppListRow(title: 'x', onTap: () => tapped = true)));
    await tester.tap(find.text('x'));
    expect(tapped, isTrue);
  });
}
