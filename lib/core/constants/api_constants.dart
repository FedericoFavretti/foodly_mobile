/// Configuración de red contra el backend hosteado en Railway.
abstract final class ApiConstants {
  /// Backend API (Railway). Override: `--dart-define=API_BASE_URL=...`
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://proyectoequipo32026-test.up.railway.app',
  );

  // ── Usuarios ──────────────────────────────────────────────────────────────
  static const loginEndpoint = '/api/v1/usuarios/login';
  static const logoutEndpoint = '/api/v1/usuarios/logout';
  static const activarCuentaEndpoint = '/api/v1/usuarios/activar';
  static const eliminarCuentaEndpoint = '/api/v1/usuarios/mi-cuenta';

  // ── Cliente ───────────────────────────────────────────────────────────────
  static const registroEndpoint = '/api/v1/clientes/registro';
  static const listarLocalesEndpoint = '/api/v1/clientes/listar_locales';
  static const busquedaPlatosEndpoint = '/api/v1/clientes/busqueda';

  // ── Pedidos ───────────────────────────────────────────────────────────────
  static const pedidosEndpoint = '/api/v1/pedidos';
  static const historialPedidosEndpoint = '/api/v1/pedidos/mi-historial';

  // ── Reclamos / calificaciones ─────────────────────────────────────────────
  static const reclamoEndpoint = '/api/v1/reclamos/realizar_reclamo';
  static const calificacionEndpoint = '/api/v1/calificaciones/calificar';

  /// Catálogo real por defecto. Mock: `--dart-define=USE_MOCK_CATALOG=true`
  static const useMockCatalog = bool.fromEnvironment(
    'USE_MOCK_CATALOG',
    defaultValue: false,
  );

  static const timeoutSeconds = 15;
}
