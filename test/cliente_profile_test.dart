import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/data/models/cliente_profile_model.dart';

void main() {
  test('ClienteProfileModel.fromJson parsea dirección', () {
    final profile = ClienteProfileModel.fromJson({
      'id': 7,
      'email': 'cliente@test.com',
      'nombre': 'Juan',
      'apellido': 'Pérez',
      'direccion': {
        'calle': 'Av. Italia',
        'numero': '100',
        'ciudad': 'Montevideo',
        'codigoPostal': '11000',
      },
    });

    expect(profile.id, 7);
    expect(profile.direccion?.calle, 'Av. Italia');
  });
}
