import 'plato_model.dart';

/// Promoción activa sobre un plato (`promociones[]` en busqueda).
class PromocionModel {
  const PromocionModel({
    required this.id,
    required this.descuento,
    this.descripcion,
    this.idPlato,
    this.plato,
  });

  final int id;
  final double descuento;
  final String? descripcion;
  final int? idPlato;
  final PlatoModel? plato;

  factory PromocionModel.fromJson(Map<String, dynamic> json) {
    final platoJson = json['dtPlato'] ?? json['plato'];
    PlatoModel? plato;
    if (platoJson is Map<String, dynamic>) {
      plato = PlatoModel.tryFromJson(platoJson);
    }

    final id = PlatoModel.readInt(json['id']);
    if (id == null) {
      throw FormatException('Promoción sin id válido: $json');
    }

    return PromocionModel(
      id: id,
      descuento: PlatoModel.readDouble(json['descuento']) ?? 0,
      descripcion: json['descripcion'] as String?,
      idPlato: PlatoModel.readInt(json['idPlato']) ?? plato?.id,
      plato: plato,
    );
  }

  static PromocionModel? tryFromJson(Map<String, dynamic> json) {
    try {
      return PromocionModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
