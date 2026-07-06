import 'dart:convert';

abstract final class JwtDecoder {
  static Map<String, dynamic> decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('JWT inválido');
    }
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  static String? role(String token) {
    final payload = decodePayload(token);
    final role = payload['role'];
    return role?.toString();
  }

  static String? email(String token) {
    final payload = decodePayload(token);
    final subject = payload['sub'];
    return subject?.toString();
  }

  /// Mobile solo admite clientes. El backend hoy puede emitir ROLE_USER.
  static bool isClienteRole(String? role) {
    if (role == null || role.isEmpty) return true;
    final upper = role.toUpperCase();
    if (upper.contains('ADMIN') || upper.contains('LOCAL')) return false;
    return upper.contains('CLIENTE') || upper == 'ROLE_USER' || upper == 'USER';
  }

  /// `true` si el claim `exp` ya pasó o el token es inválido.
  static bool isExpired(String token, {DateTime? now}) {
    try {
      final payload = decodePayload(token);
      final exp = payload['exp'];
      if (exp == null) return false;

      final expSeconds = exp is num
          ? exp.toInt()
          : int.tryParse(exp.toString().trim());
      if (expSeconds == null) return false;

      final reference = now ?? DateTime.now();
      return reference.millisecondsSinceEpoch >= expSeconds * 1000;
    } catch (_) {
      return true;
    }
  }
}
