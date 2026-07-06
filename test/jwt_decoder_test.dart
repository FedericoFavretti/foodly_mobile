import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/core/auth/jwt_decoder.dart';

String _fakeToken(Map<String, dynamic> payload) {
  final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return 'header.$encoded.signature';
}

void main() {
  group('JwtDecoder', () {
    test('extrae role del payload', () {
      final token = _fakeToken({'role': 'ROLE_USER'});
      expect(JwtDecoder.role(token), 'ROLE_USER');
    });

    test('acepta ROLE_USER como cliente', () {
      expect(JwtDecoder.isClienteRole('ROLE_USER'), isTrue);
    });

    test('acepta ROLE_Cliente del backend real', () {
      expect(JwtDecoder.isClienteRole('ROLE_Cliente'), isTrue);
    });

    test('rechaza ROLE_ADMIN', () {
      expect(JwtDecoder.isClienteRole('ROLE_ADMIN'), isFalse);
    });

    test('rechaza ROLE_Local', () {
      expect(JwtDecoder.isClienteRole('ROLE_Local'), isFalse);
    });

    test('isExpired detecta token vencido', () {
      final expiredAt = DateTime.utc(2020, 1, 1, 12, 0);
      final token = _fakeToken({
        'role': 'ROLE_USER',
        'exp': expiredAt.millisecondsSinceEpoch ~/ 1000,
      });

      expect(
        JwtDecoder.isExpired(token, now: expiredAt.add(const Duration(minutes: 1))),
        isTrue,
      );
    });

    test('isExpired acepta token vigente', () {
      final now = DateTime.utc(2026, 6, 1, 12, 0);
      final token = _fakeToken({
        'role': 'ROLE_USER',
        'exp': now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      });

      expect(JwtDecoder.isExpired(token, now: now), isFalse);
    });
  });
}
