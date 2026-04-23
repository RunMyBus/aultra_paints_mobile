// test/widgets/primitives/app_dialog_test.dart
import 'package:aultra_paints_mobile/theme/app_theme.dart';
import 'package:aultra_paints_mobile/widgets/primitives/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppDialog renders title, body, actions', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(builder: (ctx) {
          return ElevatedButton(
            onPressed: () => showAppDialog(
              context: ctx,
              title: 'Confirm',
              body: const Text('Are you sure?'),
              actions: [
                AppDialogAction(label: 'Cancel', onPressed: () {}),
                AppDialogAction(label: 'OK', onPressed: () {}, primary: true),
              ],
            ),
            child: const Text('open'),
          );
        }),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Are you sure?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });
}
