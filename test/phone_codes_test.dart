import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/validators/phone_codes.dart';
import 'package:foodly_mobile/core/validators/phone_format.dart';

void main() {
  group('PhoneCodes', () {
    test('split vacío devuelve Uruguay por defecto', () {
      final result = PhoneCodes.split('');
      expect(result.country.iso, 'UY');
      expect(result.number, '');
    });

    test('split reconoce Uruguay sin confundirlo con otro código', () {
      final result = PhoneCodes.split('+598991234567');
      expect(result.country.iso, 'UY');
      expect(result.number, '991234567');
    });

    test('split no confunde +1 con +598 (prueba longitudes de código)', () {
      final result = PhoneCodes.split('+15551234567');
      expect(result.country.iso, 'US');
      expect(result.number, '5551234567');
    });

    test('split reconoce Argentina', () {
      final result = PhoneCodes.split('+5491122334455');
      expect(result.country.iso, 'AR');
      expect(result.number, '91122334455');
    });

    test('split sin match conocido asume Uruguay con el string entero', () {
      final result = PhoneCodes.split('+9999999999');
      expect(result.country.iso, 'UY');
      expect(result.number, '+9999999999');
    });

    test('todos los códigos son únicos (necesario para split sin ambigüedad)', () {
      final codes = PhoneCodes.all.map((c) => c.code).toList();
      expect(codes.toSet().length, codes.length);
    });
  });

  group('PhoneFormat', () {
    test('formatTelefonoFijo saca el prefijo +598', () {
      expect(PhoneFormat.formatTelefonoFijo('+59824871234'), '24871234');
    });

    test('formatTelefonoFijo tolera valores sin el prefijo', () {
      expect(PhoneFormat.formatTelefonoFijo('24871234'), '24871234');
    });

    test('formatTelefonoFijo con null o vacío devuelve string vacío', () {
      expect(PhoneFormat.formatTelefonoFijo(null), '');
      expect(PhoneFormat.formatTelefonoFijo(''), '');
    });
  });
}
