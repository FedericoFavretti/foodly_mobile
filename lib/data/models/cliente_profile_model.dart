import 'direccion_model.dart';

class ClienteProfileModel {
  const ClienteProfileModel({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    this.fotoUrl,
    this.direccion,
    this.celular,
  });

  final int id;
  final String email;
  final String nombre;
  final String apellido;
  final String? fotoUrl;
  final DireccionModel? direccion;
  /// E.164 completo (ej. `+598991234567`). Solo llega en la respuesta de
  /// `PUT /usuarios/perfil` — no hay forma de precargarlo desde otro lado.
  final String? celular;

  String get nombreCompleto => '$nombre $apellido'.trim();

  bool get tieneFoto => fotoUrl != null && fotoUrl!.trim().isNotEmpty;

  factory ClienteProfileModel.fromJson(Map<String, dynamic> json) {
    final id = _readInt(json['id']);
    if (id == null) {
      throw FormatException('Cliente sin id válido: $json');
    }

    final direccionJson = json['direccion'];
    return ClienteProfileModel(
      id: id,
      email: json['email'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      fotoUrl: _readString(json['foto']),
      direccion: direccionJson is Map<String, dynamic>
          ? DireccionModel.fromJson(direccionJson)
          : null,
      celular: _readString(json['celular']),
    );
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String? _readString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Parsea perfil desde la respuesta de login cuando el backend incluye datos del cliente.
  static ClienteProfileModel? tryFromLoginJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['email'] == null) return null;
    try {
      final profile = ClienteProfileModel.fromJson(json);
      if (profile.nombre.trim().isEmpty &&
          profile.apellido.trim().isEmpty &&
          !profile.tieneFoto &&
          profile.direccion == null) {
        return null;
      }
      return profile;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nombre': nombre,
        'apellido': apellido,
        if (fotoUrl != null) 'foto': fotoUrl,
        if (direccion != null)
          'direccion': {
            'calle': direccion!.calle,
            'numero': direccion!.numero,
            'ciudad': direccion!.ciudad,
            'codigoPostal': direccion!.codigoPostal,
          },
        if (celular != null) 'celular': celular,
      };

  ClienteProfileModel copyWith({
    String? nombre,
    String? apellido,
    String? fotoUrl,
    DireccionModel? direccion,
    String? celular,
  }) {
    return ClienteProfileModel(
      id: id,
      email: email,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      direccion: direccion ?? this.direccion,
      celular: celular ?? this.celular,
    );
  }
}
