import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/validators/form_validators.dart';

void main() {
  group('FormValidators', () {
    test('email válido retorna null', () {
      expect(FormValidators.email('cliente@foodly.com'), isNull);
    });

    test('email inválido retorna mensaje', () {
      expect(FormValidators.email('invalido'), isNotNull);
    });

    test('contraseña cumple política', () {
      expect(FormValidators.password('Clave123'), isNull);
    });

    test('contraseña débil falla', () {
      expect(FormValidators.password('clave'), isNotNull);
    });

    test('cédula uruguaya válida', () {
      expect(FormValidators.cedula('12345678'), isNull);
    });

    test('confirmación debe coincidir', () {
      expect(
        FormValidators.confirmPassword('Clave123', 'Clave123'),
        isNull,
      );
      expect(
        FormValidators.confirmPassword('Clave123', 'Otra123'),
        isNotNull,
      );
    });
  });
}
