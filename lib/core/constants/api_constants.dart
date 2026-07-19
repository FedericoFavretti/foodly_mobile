/// Configuración de red contra el backend hosteado en Railway.
abstract final class ApiConstants {
  /// Backend API (Railway). Override: `--dart-define=API_BASE_URL=...`
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://proyectoequipo32026-production-f1f5.up.railway.app',
  );

  // ── Usuarios ──────────────────────────────────────────────────────────────
  static const loginEndpoint = '/api/v1/usuarios/login';
  static const logoutEndpoint = '/api/v1/usuarios/logout';
  static const activarCuentaEndpoint = '/api/v1/usuarios/activar';
  static const reenviarActivacionEndpoint =
      '/api/v1/usuarios/reenviar-activacion';
  static const recuperarContraCorreoEndpoint =
      '/api/v1/usuarios/recuperar_contra_correo';
  static const recuperarContraEndpoint = '/api/v1/usuarios/recuperar';
  static const eliminarCuentaEndpoint = '/api/v1/usuarios/mi-cuenta';
  static const perfilEndpoint = '/api/v1/usuarios/perfil';
  static const cambiarPasswdIniciarEndpoint =
      '/api/v1/usuarios/cambiar-passwd/iniciar';
  static const cambiarPasswdVerificarEndpoint =
      '/api/v1/usuarios/cambiar-passwd/verificar-codigo';
  static const cambiarPasswdConfirmarEndpoint =
      '/api/v1/usuarios/cambiar-passwd/confirmar';
  static const cambiarCorreoIniciarEndpoint =
      '/api/v1/usuarios/cambiar-correo/iniciar';
  static const cambiarCorreoConfirmarEndpoint =
      '/api/v1/usuarios/cambiar-correo/confirmar';

  // ── Cliente ───────────────────────────────────────────────────────────────
  static const registroEndpoint = '/api/v1/clientes/registro';
  static const googleAuthEndpoint = '/api/v1/clientes/google';
  static const googleIniciarRegistroEndpoint =
      '/api/v1/clientes/google/registro/iniciar';
  static const googleCompletarRegistroEndpoint =
      '/api/v1/clientes/google/registro/completar';

  // Endpoints exclusivos para flujo móvil (ID token JWT via Credential Manager)
  static const googleMobileAuthEndpoint = '/api/v1/clientes/google/mobile';
  static const googleMobileIniciarRegistroEndpoint =
      '/api/v1/clientes/google/mobile/registro/iniciar';
  static const listarLocalesEndpoint = '/api/v1/clientes/listar_locales';
  static const busquedaPlatosEndpoint = '/api/v1/clientes/busqueda';
  static const localesPopularesEndpoint = '/api/v1/clientes/locales-populares';
  static const platosMasPedidosEndpoint = '/api/v1/clientes/platos-mas-pedidos';

  /// Fallback si `/clientes/busqueda` falla (p. ej. error al procesar promos).
  /// Requiere rol Local en backend; si responde 403 se ignora.
  static String platosLocalFallbackEndpoint(int localId) =>
      '/api/v1/locales/busqueda_plato_local/$localId';

  /// Perfil público de un local (incluye `celular`/`telefonoFijo`).
  static String localPerfilEndpoint(int localId) =>
      '/api/v1/locales/$localId/perfil';

  // ── Pedidos ───────────────────────────────────────────────────────────────
  static const pedidosEndpoint = '/api/v1/pedidos';
  static const historialPedidosEndpoint = '/api/v1/pedidos/mi-historial';

  static String pedidoByIdEndpoint(int pedidoId) =>
      '$pedidosEndpoint/$pedidoId';

  static String cancelarPedidoEndpoint(int pedidoId) =>
      '$pedidosEndpoint/$pedidoId/cancelar';

  static String reintentarPagoEndpoint(int pedidoId) =>
      '$pedidosEndpoint/$pedidoId/reintentar-pago';

  static String pedidoClienteEndpoint(int clienteId) =>
      '$pedidosEndpoint/clientes/$clienteId';

  // ── Notificaciones ────────────────────────────────────────────────────────
  static const notificacionesMiasEndpoint = '/api/v1/notificaciones/mias';
  static const notificacionTokenEndpoint = '/api/v1/notificaciones/token';

  static String notificacionLeidaEndpoint(int id) =>
      '/api/v1/notificaciones/$id/leida';

  // ── Reclamos / calificaciones ─────────────────────────────────────────────
  static const reclamoBaseEndpoint = '/api/v1/reclamos';
  static const reclamoEndpoint = '$reclamoBaseEndpoint/realizar_reclamo';

  static String miReclamoPedidoEndpoint(int pedidoId) =>
      '$reclamoBaseEndpoint/mi-reclamo/$pedidoId';

  /// Alias legado usado en repositorio.
  static const miReclamoEndpoint = '$reclamoBaseEndpoint/mi-reclamo';
  static const calificacionesBaseEndpoint = '/api/v1/calificaciones';
  static const calificacionEndpoint = '/api/v1/calificaciones/calificar';

  static String miCalificacionLocalEndpoint(int localId) =>
      '/api/v1/calificaciones/locales/$localId/mi-calificacion';

  static String calificacionGlobalClienteEndpoint(int clienteId) =>
      '/api/v1/calificaciones/$clienteId/calificacion';

  static String calificacionDetalleClienteEndpoint(int clienteId) =>
      '/api/v1/calificaciones/$clienteId/calificacion/detalle';

  /// Catálogo real por defecto. Mock: `--dart-define=USE_MOCK_CATALOG=true`
  static const useMockCatalog = bool.fromEnvironment(
    'USE_MOCK_CATALOG',
    defaultValue: false,
  );

  static const timeoutSeconds = 15;
}
