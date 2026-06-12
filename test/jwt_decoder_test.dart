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

    test('rechaza ROLE_ADMIN', () {
      expect(JwtDecoder.isClienteRole('ROLE_ADMIN'), isFalse);
    });
  });
}
