/// Información básica del usuario retornada en el login.
class UsuarioInfoModel {
  const UsuarioInfoModel({
    required this.id,
    required this.email,
    required this.tipo,
  });

  final int id;
  final String email;
  final String tipo;

  factory UsuarioInfoModel.fromJson(Map<String, dynamic> json) {
    return UsuarioInfoModel(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      tipo: json['tipo'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'tipo': tipo,
      };
}
