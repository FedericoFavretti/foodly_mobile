/// Configuración de red. En producción usar --dart-define o flavor.
abstract final class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const loginEndpoint = '/auth/login';
  static const registroEndpoint = '/api/v1/clientes/registro';
  static const localesEndpoint = '/api/v1/clientes';
  static const perfilClienteEndpoint = '/api/v1/clientes/perfil';
  static const pedidosEndpoint = '/api/v1/pedidos';
  static const historialClienteEndpoint = '/api/v1/pedidos/cliente';

  /// `true` hasta que `ClienteService.listarLocales()` esté implementado.
  static const useMockCatalog = bool.fromEnvironment(
    'USE_MOCK_CATALOG',
    defaultValue: true,
  );

  static const timeoutSeconds = 15;
}
