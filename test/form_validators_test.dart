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

    test('celular vacío es válido (campo opcional)', () {
      expect(FormValidators.celular(''), isNull);
      expect(FormValidators.celular(null), isNull);
    });

    test('celular E.164 válido retorna null', () {
      expect(FormValidators.celular('+598991234567'), isNull);
      expect(FormValidators.celular('+5491122334455'), isNull);
    });

    test('celular sin código de país o mal formado falla', () {
      expect(FormValidators.celular('099123456'), isNotNull);
      expect(FormValidators.celular('+0991234567'), isNotNull);
      expect(FormValidators.celular('+598'), isNotNull);
    });
  });
}
