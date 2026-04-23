// test/widgets/primitives/app_text_field_test.dart
import 'package:aultra_paints_mobile/theme/app_theme.dart';
import 'package:aultra_paints_mobile/widgets/primitives/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(theme: AppTheme.light(), home: Scaffold(body: w));

  testWidgets('AppTextField renders label and hint', (tester) async {
    await tester.pumpWidget(wrap(const AppTextField(label: 'Mobile', hint: '9xxxxxxxxx')));
    expect(find.text('MOBILE'), findsOneWidget);
    expect(find.text('9xxxxxxxxx'), findsOneWidget);
  });

  testWidgets('AppTextField invokes onChanged', (tester) async {
    String last = '';
    await tester.pumpWidget(wrap(AppTextField(label: 'X', onChanged: (v) => last = v)));
    await tester.enterText(find.byType(TextField), 'hello');
    expect(last, 'hello');
  });
}
