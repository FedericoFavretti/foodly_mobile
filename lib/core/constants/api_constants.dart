/// Configuración de red. En producción usar --dart-define o flavor.
abstract final class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const loginEndpoint = '/api/v1/usuarios/login';
  static const registroEndpoint = '/api/v1/clientes/registro';
  static const localesEndpoint = '/api/v1/clientes';
  static const perfilClienteEndpoint = '/api/v1/usuarios/perfil';
  static const pedidosEndpoint = '/api/v1/pedidos';
  static const historialClienteEndpoint = '/api/v1/pedidos/clientes/{idCliente}';
  static const logoutEndpoint = '/api/v1/usuarios/logout';
  static const reclamoEndpoint = '/api/v1/reclamos/realizar_reclamo';
  static const calificacionEndpoint = '/api/v1/calificaciones/calificar';
  static const cancelarPedidoEndpoint = '/api/v1/pedidos/{idPedido}/cancelar';

  /// `true` hasta que `ClienteService.listarLocales()` esté implementado.
  static const useMockCatalog = bool.fromEnvironment(
    'USE_MOCK_CATALOG',
    defaultValue: true,
  );

  static const timeoutSeconds = 15;
}
