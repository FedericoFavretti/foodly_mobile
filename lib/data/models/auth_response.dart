import 'usuario_info_model.dart';

class AuthResponse {
  const AuthResponse({
    required this.token,
    this.usuario,
  });

  final String token;
  final UsuarioInfoModel? usuario;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      usuario: json['usuario'] != null
          ? UsuarioInfoModel.fromJson(json['usuario'] as Map<String, dynamic>)
          : null,
    );
  }
}
