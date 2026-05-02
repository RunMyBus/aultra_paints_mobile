// test/widgets/primitives/app_card_test.dart
import 'package:aultra_paints_mobile/theme/app_theme.dart';
import 'package:aultra_paints_mobile/widgets/primitives/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(theme: AppTheme.light(), home: Scaffold(body: w));

  testWidgets('AppCard renders child and has a decoration with radius 14', (tester) async {
    await tester.pumpWidget(wrap(const AppCard(child: Text('hello'))));
    expect(find.text('hello'), findsOneWidget);
    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration as BoxDecoration;
    expect((decoration.borderRadius as BorderRadius).topLeft.x, 14);
    expect(decoration.color, const Color(0xFFFFFFFF));
  });

  testWidgets('AppCard.featured uses featured shadow', (tester) async {
    await tester.pumpWidget(wrap(const AppCard(emphasis: AppCardEmphasis.featured, child: Text('hi'))));
    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.boxShadow!.first.blurRadius, 18);
  });
}
