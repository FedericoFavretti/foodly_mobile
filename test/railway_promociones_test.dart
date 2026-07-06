import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/constants/api_constants.dart';
import 'package:foodly_mobile/core/network/api_client.dart';
import 'package:foodly_mobile/data/repositories/catalog_repository.dart';
import 'package:foodly_mobile/domain/session/session_manager.dart';
import 'package:http/http.dart' as http;

/// Smoke test contra Railway. Solo corre si pasás credenciales:
///
/// ```powershell
/// flutter test test/railway_promociones_test.dart `
///   --dart-define=FOODLY_EMAIL=tu@correo.com `
///   --dart-define=FOODLY_PASSWD=TuClave123
/// ```
void main() {
  const email = String.fromEnvironment('FOODLY_EMAIL');
  const passwd = String.fromEnvironment('FOODLY_PASSWD');
  final hasCredentials = email.isNotEmpty && passwd.isNotEmpty;

  group('Railway promociones (live)', () {
    setUp(() => SessionManager.enableMemoryStorageForTest());

    test(
      'login, busqueda por local y platos con promo',
      () async {
        final api = ApiClient(client: http.Client());
        final repository = CatalogRepository();

        final loginResponse = await api.post(
          ApiConstants.loginEndpoint,
          {'email': email, 'passwd': passwd},
        );
        expect(
          loginResponse.statusCode,
          200,
          reason: 'Login falló: ${loginResponse.body}',
        );

        final loginJson =
            jsonDecode(loginResponse.body) as Map<String, dynamic>;
        final token = loginJson['token'] as String?;
        expect(token, isNotNull);

        await SessionManager.saveToken(token!);

        final locales = await repository.listarLocales();
        expect(locales, isNotEmpty, reason: 'No hay locales en Railway');

        final localId = locales.first.id;
        final platos = await repository.platosDeLocal(localId);

        expect(
          platos,
          isNotEmpty,
          reason: 'El menú del local $localId no devolvió platos',
        );

        final conPromo = platos.where((p) => p.tienePromocion).toList();
        // ignore: avoid_print
        print(
          'Local ${locales.first.nombre} (id=$localId): '
          '${platos.length} platos, ${conPromo.length} con promoción',
        );
        for (final plato in conPromo) {
          // ignore: avoid_print
          print(
            '  - ${plato.nombre}: '
            '\$${plato.precioOriginal?.toStringAsFixed(0) ?? "?"} → '
            '\$${plato.precioFinal.toStringAsFixed(0)} '
            '(${plato.descuentoPercent ?? "?"}%)',
          );
        }

        if (conPromo.isEmpty) {
          // ignore: avoid_print
          print(
            'Aviso: ningún plato trae tienePromocion=true. '
            'Verificá que el local tenga promos activas en Railway.',
          );
        } else {
          expect(
            conPromo.every(
              (p) =>
                  p.precioFinal > 0 &&
                  (p.precioOriginal == null || p.precioFinal <= p.precioOriginal!),
            ),
            isTrue,
          );
        }
      },
      skip: hasCredentials ? false : 'Definir FOODLY_EMAIL y FOODLY_PASSWD',
    );
  });
}
