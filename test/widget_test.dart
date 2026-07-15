import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodly_mobile/screens/home_screen.dart';
import 'package:foodly_mobile/theme/foodly_theme.dart';

// Testea la HomeScreen directamente para evitar que _AppStartup
// (que llama a SessionManager con I/O real) cuelgue pumpAndSettle.
void main() {
  testWidgets('Muestra la pantalla principal de Foodly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FoodlyTheme.light,
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Foodly'), findsWidgets);
    expect(find.text('Miles de sabores.\nUn solo lugar.'), findsOneWidget);
    expect(find.text('Lo más pedido, directo a tu casa'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo funciona?'), findsOneWidget);
  });
}
