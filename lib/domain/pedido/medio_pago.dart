/// Medios de pago soportados por el backend (mismo contrato que el frontend web).
enum MedioPago {
  mercadoPago('mercadopago'),
  efectivo('efectivo');

  const MedioPago(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case MedioPago.mercadoPago:
        return 'Mercado Pago';
      case MedioPago.efectivo:
        return 'Efectivo';
    }
  }

  String get descripcion {
    switch (this) {
      case MedioPago.mercadoPago:
        return 'Pagás online y completás el pago en Mercado Pago.';
      case MedioPago.efectivo:
        return 'Confirmás el pedido ahora y pagás al recibirlo.';
    }
  }
}
