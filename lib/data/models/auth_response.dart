import 'usuario_info_model.dart';

class AuthResponse {
  const AuthResponse({
    required this.token,
    this.id,
    this.email,
    this.tipo,
  });

  final String token;
  final int? id;
  final String? email;
  final String? tipo;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      email: json['email'] as String?,
      tipo: json['tipo'] as String?,
    );
  }
  
  /// Convierte la respuesta a UsuarioInfoModel para compatibilidad
  UsuarioInfoModel? get usuario {
    if (id != null && email != null && tipo != null) {
      return UsuarioInfoModel(id: id!, email: email!, tipo: tipo!);
    }
    return null;
  }
}
