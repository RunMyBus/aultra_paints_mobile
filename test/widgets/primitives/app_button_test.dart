// test/widgets/primitives/app_button_test.dart
import 'package:aultra_paints_mobile/theme/app_theme.dart';
import 'package:aultra_paints_mobile/widgets/primitives/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(theme: AppTheme.light(), home: Scaffold(body: w));

  testWidgets('AppButton.filled invokes onPressed', (tester) async {
    var count = 0;
    await tester.pumpWidget(wrap(AppButton.filled(label: 'Go', onPressed: () => count++)));
    await tester.tap(find.text('Go'));
    expect(count, 1);
  });

  testWidgets('AppButton.outlined renders OutlinedButton', (tester) async {
    await tester.pumpWidget(wrap(AppButton.outlined(label: 'X', onPressed: () {})));
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('AppButton.text renders TextButton', (tester) async {
    await tester.pumpWidget(wrap(AppButton.text(label: 'x', onPressed: () {})));
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets('loading state disables tap and shows spinner', (tester) async {
    var count = 0;
    await tester.pumpWidget(wrap(AppButton.filled(label: 'Go', loading: true, onPressed: () => count++)));
    await tester.tap(find.byType(ElevatedButton));
    expect(count, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
