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
  static const reclamoEndpoint = '/api/v1/reclamos/realizar_reclamo';
  static const calificacionEndpoint = '/api/v1/calificaciones/calificar';
  static const logoutEndpoint = '/api/v1/usuarios/logout';
  static const cancelarPedidoEndpoint = '/api/v1/pedidos/{idPedido}/cancelar';

  // TODO(BLOQUEADO): Estos endpoints requieren clienteId del usuario autenticado.
  // Backend debe proveer GET /api/v1/clientes/perfil o GET /api/v1/usuarios/me
  // para obtener el clienteId. Una vez resuelto, actualizar a funciones:
  // - historialClienteEndpoint(int idCliente) => '/api/v1/pedidos/clientes/$idCliente'
  // - eliminarCuentaEndpoint(int idCliente) => '/api/v1/usuarios/clientes/$idCliente/cuenta-dev'
  
  /// Endpoint temporal - Requiere actualización cuando backend provea perfil
  static const historialClienteEndpoint = '/api/v1/pedidos/cliente';
  
  /// Endpoint temporal - Requiere actualización cuando backend provea perfil
  static const eliminarCuentaEndpoint = '/api/v1/clientes/perfil';

  /// Flag para usar datos mock o API real del catálogo.
  /// Backend GET /api/v1/clientes ahora está funcional (a partir de jun-2026).
  /// Para pruebas con backend real: flutter run --dart-define=USE_MOCK_CATALOG=false
  /// Para desarrollo con mocks (sin backend): flutter run (default true)
  static const useMockCatalog = bool.fromEnvironment(
    'USE_MOCK_CATALOG',
    defaultValue: true,
  );

  static const timeoutSeconds = 15;
}
