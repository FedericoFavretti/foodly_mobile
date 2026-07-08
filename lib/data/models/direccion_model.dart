class DireccionModel {
  const DireccionModel({
    required this.calle,
    required this.numero,
    required this.ciudad,
    this.codigoPostal,
  });

  final String calle;
  final String numero;
  final String ciudad;
  final String? codigoPostal;

  factory DireccionModel.fromJson(Map<String, dynamic> json) {
    return DireccionModel(
      calle: json['calle'] as String? ?? '',
      numero: json['numero'] as String? ?? '',
      ciudad: json['ciudad'] as String? ?? '',
      codigoPostal: json['codigoPostal'] as String?,
    );
  }

  String get resumen {
    final partes = <String>[
      if (calle.isNotEmpty) '$calle $numero'.trim(),
      if (ciudad.isNotEmpty) ciudad,
    ];
    return partes.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'calle': calle,
      'numero': numero,
      'ciudad': ciudad,
      if (codigoPostal != null && codigoPostal!.trim().isNotEmpty)
        'codigoPostal': codigoPostal,
    };
  }
}
