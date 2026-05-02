// test/widgets/primitives/app_app_bar_test.dart
import 'package:aultra_paints_mobile/theme/app_theme.dart';
import 'package:aultra_paints_mobile/widgets/primitives/app_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(theme: AppTheme.light(), home: Scaffold(appBar: w as PreferredSizeWidget));

  testWidgets('AppAppBar renders title and uses primary color', (tester) async {
    await tester.pumpWidget(wrap(const AppAppBar(title: 'Catalog')));
    expect(find.text('Catalog'), findsOneWidget);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, const Color(0xFF10278C));
  });

  testWidgets('AppAppBar fires leading onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(AppAppBar(
      title: 'X',
      leading: AppAppBarAction(icon: Icons.menu, onPressed: () => tapped = true),
    )));
    await tester.tap(find.byIcon(Icons.menu));
    expect(tapped, isTrue);
  });
}
