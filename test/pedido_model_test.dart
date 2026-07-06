import 'package:flutter_test/flutter_test.dart';
import 'package:foodly_mobile/data/models/pedido_response_model.dart';
import 'package:foodly_mobile/domain/pedido/pedido_delivery_time.dart';
import 'package:foodly_mobile/domain/pedido/pedido_list_filter.dart';
import 'package:foodly_mobile/domain/pedido/pedido_sort.dart';

void main() {
  group('PedidoResponseModel', () {
    test('parsea fecha y motivo de rechazo', () {
      final pedido = PedidoResponseModel.fromJson({
        'id': 10,
        'total': 500,
        'estado': 'Rechazado',
        'fecha': '2026-06-15T14:30:00',
        'motivoRechazo': 'Sin stock disponible',
        'local': {'id': 3, 'nombre': 'Burger World'},
      });

      expect(pedido.fecha, isNotNull);
      expect(pedido.motivoRechazo, 'Sin stock disponible');
      expect(pedido.fechaLegible, contains('2026'));
    });

    test('puedeCompletarPagoMercadoPago cuando hay init point pendiente', () {
      final pedido = PedidoResponseModel.fromJson({
        'id': 1,
        'total': 100,
        'estado': 'Pendiente',
        'medioDePago': 'mercadopago',
        'mpInitPoint': 'https://mp.test/checkout',
        'local': {'nombre': 'Local'},
      });

      expect(pedido.puedeCompletarPagoMercadoPago, isTrue);
      expect(pedido.medioPagoLabel, 'Mercado Pago');
    });

    test('esActivo incluye pendiente y confirmado', () {
      expect(
        PedidoResponseModel(
          id: 1,
          total: 1,
          estado: 'Pendiente',
          localNombre: 'A',
          detalles: const [],
        ).esActivo,
        isTrue,
      );
      expect(
        PedidoResponseModel(
          id: 2,
          total: 1,
          estado: 'Entregado',
          localNombre: 'A',
          detalles: const [],
        ).esActivo,
        isFalse,
      );
    });
  });

  group('PedidoSort', () {
    test('ordena por fecha más reciente primero', () {
      final sorted = PedidoSort.apply(
        [
          PedidoResponseModel(
            id: 1,
            total: 100,
            estado: 'Entregado',
            localNombre: 'A',
            detalles: const [],
            fecha: DateTime(2026, 1, 1),
          ),
          PedidoResponseModel(
            id: 2,
            total: 200,
            estado: 'Pendiente',
            localNombre: 'B',
            detalles: const [],
            fecha: DateTime(2026, 6, 1),
          ),
        ],
        PedidoSortOption.fechaReciente,
      );

      expect(sorted.first.id, 2);
    });

    test('con Todos, activos aparecen antes que entregados', () {
      final sorted = PedidoListFilter.apply(
        all: [
          PedidoResponseModel(
            id: 1,
            total: 500,
            estado: 'Entregado',
            localNombre: 'A',
            detalles: const [],
            fecha: DateTime(2026, 6, 1),
          ),
          PedidoResponseModel(
            id: 2,
            total: 100,
            estado: 'Pendiente',
            localNombre: 'B',
            detalles: const [],
            fecha: DateTime(2026, 1, 1),
          ),
        ],
        filtroEstado: null,
        sort: PedidoSortOption.fechaReciente,
      );

      expect(sorted.first.id, 2);
      expect(sorted.first.estado, 'Pendiente');
    });

    test('normaliza estado en minúsculas desde el backend', () {
      final pedido = PedidoResponseModel.fromJson({
        'id': 3,
        'total': 120,
        'estado': 'pendiente',
        'local': {'id': 1, 'nombre': 'Local'},
      });

      expect(pedido.estado, 'Pendiente');
      expect(pedido.esActivo, isTrue);
    });

    test('parsea tiempoEstEntrega ISO-8601 en minutos', () {
      final pedido = PedidoResponseModel.fromJson({
        'id': 4,
        'total': 300,
        'estado': 'Confirmado',
        'tiempoEstEntrega': 'PT25M',
        'local': {'nombre': 'Local'},
      });

      expect(pedido.tiempoEntregaMinutos, 25);
      expect(pedido.tieneTiempoEntrega, isTrue);
    });
  });

  group('PedidoDeliveryTime', () {
    test('parseMinutes acepta segundos en objeto', () {
      expect(PedidoDeliveryTime.parseMinutes({'seconds': 1800}), 30);
    });

    test('parseMinutes acepta número en minutos', () {
      expect(PedidoDeliveryTime.parseMinutes(45), 45);
    });
  });
}
