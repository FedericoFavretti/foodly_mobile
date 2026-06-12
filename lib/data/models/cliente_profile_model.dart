import 'direccion_model.dart';

class ClienteProfileModel {
  const ClienteProfileModel({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    this.direccion,
  });

  final int id;
  final String email;
  final String nombre;
  final String apellido;
  final DireccionModel? direccion;

  factory ClienteProfileModel.fromJson(Map<String, dynamic> json) {
    final direccionJson = json['direccion'];
    return ClienteProfileModel(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      direccion: direccionJson is Map<String, dynamic>
          ? DireccionModel.fromJson(direccionJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nombre': nombre,
        'apellido': apellido,
        if (direccion != null)
          'direccion': {
            'calle': direccion!.calle,
            'numero': direccion!.numero,
            'ciudad': direccion!.ciudad,
            'codigoPostal': direccion!.codigoPostal,
          },
      };
}
