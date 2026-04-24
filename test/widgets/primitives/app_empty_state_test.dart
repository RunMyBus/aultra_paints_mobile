// test/widgets/primitives/app_empty_state_test.dart
import 'package:aultra_paints_mobile/theme/app_theme.dart';
import 'package:aultra_paints_mobile/widgets/primitives/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(theme: AppTheme.light(), home: Scaffold(body: w));

  testWidgets('AppEmptyState renders title, message, and optional CTA', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(AppEmptyState(
      icon: Icons.inbox_outlined,
      title: 'No orders yet',
      message: 'Place your first order to see it here.',
      ctaLabel: 'Browse catalog',
      onCta: () => tapped = true,
    )));
    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('Place your first order to see it here.'), findsOneWidget);
    await tester.tap(find.text('Browse catalog'));
    expect(tapped, isTrue);
  });
}
