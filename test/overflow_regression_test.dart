import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/data/models/plato_model.dart';
import 'package:foodly_mobile/domain/catalog/plato_busqueda_item.dart';
import 'package:foodly_mobile/screens/activate_account_screen.dart';
import 'package:foodly_mobile/screens/change_email_screen.dart';
import 'package:foodly_mobile/theme/foodly_theme.dart';
import 'package:foodly_mobile/widgets/calificar_dialog.dart';
import 'package:foodly_mobile/widgets/foodly_button.dart';
import 'package:foodly_mobile/widgets/plato_busqueda_card.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reproduce los overflows reportados en pantallas angostas (~360dp de
/// ancho, el piso habitual de un celular real) y falla si el layout se
/// rompe de nuevo. Se detectó corriendo la app en un emulador con
/// `wm size 720x1560` (densidad 320 → ~360dp lógicos).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// Ancho angosto realista (~360dp lógicos, equivalente al que reprodujo
  /// los overflows reales en el emulador).
  void useNarrowScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(720, 1560);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'CalificarDialog: fila de 5 estrellas no desborda en pantalla angosta',
    (tester) async {
      useNarrowScreen(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: FoodlyTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showCalificarDialog(
                    context: context,
                    localNombre: 'Local de prueba',
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.byType(CalificarDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'FoodlyButton: label largo hace ellipsis en vez de desbordar',
    (tester) async {
      useNarrowScreen(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: FoodlyTheme.light,
          home: Scaffold(
            body: Center(
              child: FoodlyButton(
                label: 'ENVIAR ENLACE DE CONFIRMACIÓN',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'PlatoBusquedaCard: nombre de plato en 2 líneas no desborda la grilla',
    (tester) async {
      useNarrowScreen(tester);

      const item = PlatoBusquedaItem(
        plato: PlatoModel(
          id: 1,
          nombre: 'Bacon Cheese Superburger',
          descripcion: '',
          precio: 480,
          imagenes: [],
          disponible: true,
          localId: 1,
        ),
        localNombre: 'SuperBurger',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: FoodlyTheme.light,
          home: Scaffold(
            body: GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.6,
              ),
              children: [
                PlatoBusquedaCard(item: item, onTap: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ActivateAccountScreen no desborda en pantalla angosta',
    (tester) async {
      useNarrowScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: ActivateAccountScreen(initialEmail: 'cliente@test.com'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ChangeEmailScreen no desborda en pantalla angosta',
    (tester) async {
      useNarrowScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: ChangeEmailScreen(currentEmail: 'cliente@test.com'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
