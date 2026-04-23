// test/widgets/primitives/app_snack_test.dart
import 'package:aultra_paints_mobile/theme/app_theme.dart';
import 'package:aultra_paints_mobile/widgets/primitives/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppSnack.show displays message', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(builder: (ctx) {
          return ElevatedButton(
            onPressed: () => AppSnack.show(ctx, 'Saved', tone: AppSnackTone.success),
            child: const Text('open'),
          );
        }),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    expect(find.text('Saved'), findsOneWidget);
  });
}
