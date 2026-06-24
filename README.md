# Foodly Mobile

App Flutter para pedidos de comida a domicilio — cliente del sistema Foodly.

---

## Requisitos previos

| Herramienta | Versión mínima |
|-------------|---------------|
| Flutter SDK | 3.11.x |
| Dart SDK | 3.11.x |
| Android SDK | API 23+ (Android 6.0) |
| Java | 17 |

```bash
flutter --version   # verificar versión
flutter doctor      # verificar entorno
```

---

## Instalación

```bash
git clone <repo>
cd foodly_mobile
flutter pub get
```

---

## Variables de entorno / Configuración

La URL base del backend se configura con `--dart-define`:

```bash
# Emulador Android (default)
flutter run

# Dispositivo físico en red local (reemplazar con la IP del servidor)
flutter run --dart-define=API_BASE_URL=http://192.168.1.X:8080

# Producción (Railway u otro hosting)
flutter run --dart-define=API_BASE_URL=https://api.foodly.com
```

### Modo mock del catálogo

**ACTUALIZACIÓN (Fase 8):** El catálogo ahora usa el API real del backend por defecto.
El backend tiene implementado `GET /api/v1/clientes` (listar locales desde jun-2026).

```bash
# Usar API real (default) - requiere backend levantado
flutter run

# Usar mock local - solo para desarrollo sin backend
flutter run --dart-define=USE_MOCK_CATALOG=true
```

---

## Correr tests

```bash
# Todos los tests
flutter test

# Test específico
flutter test test/biometric_service_test.dart

# Con cobertura
flutter test --coverage
```

**Suite actual:** 53 tests, 0 fallos.

| Archivo | Descripción |
|---------|-------------|
| `auth_repository_test.dart` | Login, manejo de errores, tokens |
| `logout_test.dart` | Logout, limpieza de sesión local y remota |
| `biometric_service_test.dart` | Biometría (stub), preferencias SessionManager |
| `cart_notifier_test.dart` | Carrito: agregar ítems, validaciones |
| `catalog_test.dart` | Modelos, filtros, repositorio catálogo |
| `cliente_profile_test.dart` | Modelo perfil, parseo JSON |
| `cliente_repository_delete_test.dart` | Eliminar cuenta: 200, 204, 404, 405, 500 |
| `form_validators_test.dart` | Email, contraseña, cédula, confirmación |
| `historial_test.dart` | Historial, cancelación de pedidos |
| `jwt_decoder_test.dart` | Decodificación JWT, verificación de rol |
| `pedido_repository_test.dart` | Realizar pedido, validaciones |
| `widget_test.dart` | HomeScreen widget |

---

## Arquitectura

```
lib/
├── main.dart                         ← Punto de entrada + rutas con FoodlyPageRoute
├── core/
│   ├── auth/
│   │   ├── biometric_service.dart    ← Autenticación biométrica (local_auth)
│   │   └── jwt_decoder.dart          ← Decodificación y validación de JWT
│   ├── constants/
│   │   └── api_constants.dart        ← URLs, endpoints, timeouts
│   ├── errors/
│   │   └── api_exception.dart        ← Excepciones tipadas (ApiException, NetworkException)
│   ├── navigation/
│   │   └── foodly_page_route.dart    ← Transición fade+slide personalizada
│   └── network/
│       └── api_client.dart           ← HTTP client (GET, POST, DELETE, multipart)
├── data/
│   ├── models/                       ← DTOs que mapean respuestas JSON del backend
│   └── repositories/                 ← Acceso a datos (API o mock)
├── domain/
│   ├── cart/                         ← Lógica de carrito (CartNotifier)
│   └── session/                      ← JWT + preferencias en flutter_secure_storage
├── screens/                          ← Pantallas de la app
├── widgets/                          ← Componentes reutilizables
└── theme/                            ← Colores y estilos globales
```

### Principio fundamental

```
UI → Repository → ApiClient → Backend
```

La UI **nunca** llama directamente a `http`. Siempre pasa por el repositorio correspondiente.

---

## Pantallas implementadas

| Pantalla | Ruta | Estado |
|----------|------|--------|
| Home (marketing) | `/` | ✅ Completa |
| Login | `/login` | ✅ Completa + biometría |
| Registro | `/register` | ✅ Completa (multipart + foto) |
| Locales (Main) | `/app` | ✅ Mock; API cuando backend listo |
| Detalle local + platos | `/local/:id` | ✅ Mock |
| Carrito | `/cart` | ✅ Completa |
| Checkout | `/checkout` | ✅ Completa |
| Estado del pedido | `/order-status` | ✅ Completa |
| Historial de pedidos | Tab "Mis pedidos" | ✅ Mock; API cuando backend listo |
| Perfil | Tab "Perfil" | ✅ Mock; API cuando backend listo |

---

## Funcionalidades por fase

| Fase | Descripción | Estado |
|------|-------------|--------|
| 1 | Auth: login + registro JWT | ✅ Completa |
| 2 | Catálogo: locales + platos | ✅ Completa (con mock para desarrollo) |
| 3 | Pedidos: carrito → checkout → confirmación | ⏸️ Bloqueado (requiere clienteId) |
| 4 | Historial + cancelación | ⏸️ Bloqueado (requiere clienteId) |
| 5 | Navegación tabs + perfil + reclamo + calificación | ⏸️ Bloqueado (requiere clienteId) |
| 6 | Biometría + eliminar cuenta + UX polish | ✅ Completa |
| 7 | Integración backend real (endpoints actualizados) | ✅ Completa |
| 8 | Logout funcional + catálogo real por defecto | ✅ Completa |

---

## Dependencias principales

| Paquete | Versión | Uso |
|---------|---------|-----|
| `http` | ^1.2.1 | Cliente HTTP |
| `flutter_secure_storage` | ^9.2.2 | JWT en storage seguro |
| `local_auth` | ^2.3.0 | Face ID / huella dactilar |
| `image_picker` | ^1.1.2 | Foto de perfil en registro |
| `google_fonts` | ^6.2.1 | Tipografía (Nunito, DM Serif Display) |
| `shimmer` | ^3.0.0 | Skeleton loaders |

---

## Endpoints que consume

| Método | Endpoint | Estado backend | Estado mobile | Notas |
|--------|----------|----------------|---------------|-------|
| POST | `/api/v1/usuarios/login` | ✅ Funcional | ✅ Integrado (F7) | Antes `/auth/login` |
| POST | `/api/v1/usuarios/logout` | ✅ Funcional | ✅ Integrado (F8) | Cierre de sesión |
| POST | `/api/v1/clientes/registro` | ✅ Funcional | ✅ Integrado (F1) | Multipart con foto |
| GET | `/api/v1/clientes` | ✅ Funcional | ✅ Integrado (F8) | Catálogo real por defecto |
| GET | `/api/v1/clientes/{filtro}` | ✅ Funcional | ✅ Integrado (F2) | Buscar platos |
| GET | `/api/v1/usuarios/perfil` | ✅ Funcional | ✅ Integrado (F7) | Antes `/api/v1/clientes/perfil` |
| GET | `/api/v1/usuarios/perfil.usuario.id` | ❌ No disponible | ⏸️ Bloqueado | **CRÍTICO:** Backend debe incluir `usuario.id` en login |
| POST | `/api/v1/pedidos` | ✅ Funcional | ⏸️ Bloqueado | Requiere `clienteId` del login |
| GET | `/api/v1/pedidos/clientes/{idCliente}` | ✅ Funcional | ⏸️ Bloqueado | Requiere `clienteId` del login |
| POST | `/api/v1/pedidos/{id}/cancelar` | ✅ Funcional | ⏸️ Bloqueado | Backend listo, mobile requiere `clienteId` |
| POST | `/api/v1/reclamos/realizar_reclamo` | ✅ Funcional | ⏸️ Bloqueado | Requiere `clienteId` del login |
| PUT | `/api/v1/calificaciones/calificar` | ✅ Funcional | ⏸️ Bloqueado | Requiere `clienteId` del login |
| DELETE | `/api/v1/usuarios/clientes/{id}/cuenta-dev` | ✅ Funcional | ⏸️ Bloqueado | Requiere `clienteId` del login |

---

## Seguridad

- **JWT**: almacenado en `flutter_secure_storage` (EncryptedSharedPreferences en Android, Keychain en iOS).
- **Biometría**: autentica localmente para desbloquear el token ya almacenado. No hay comunicación con el backend.
- **Tokens expirados**: cualquier 401 limpia el storage y redirige al login.
- **Logs**: solo se loguean status codes en modo debug, nunca el body completo.

---

## Notas para el equipo backend

### 🚨 Bloqueador crítico: falta `clienteId` en login

**Todas las integraciones de features están bloqueadas porque mobile no puede obtener el `id` del cliente.**

Mobile necesita el `clienteId` para:
- Crear pedidos (`idCliente` en body)
- Ver historial (`/pedidos/clientes/{idCliente}`)
- Cancelar pedidos (validar pertenencia)
- Crear reclamos (`idCliente` en body)
- Calificar locales (`idCliente` en body)
- Eliminar cuenta (`/usuarios/clientes/{idCliente}/cuenta-dev`)

### Solución propuesta (RECOMENDADA)

**Incluir objeto `usuario` en la respuesta de login:**

```json
POST /api/v1/usuarios/login
Request:
{
  "email": "cliente@foodly.com",
  "password": "Clave123"
}

Response 200:
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "usuario": {
    "id": 123,
    "email": "cliente@foodly.com",
    "tipo": "CLIENTE"
  }
}
```

**Mobile ya está 100% preparado** para esta solución:
- ✅ `UsuarioInfoModel` creado
- ✅ `AuthResponse` actualizado para parsear `usuario`
- ✅ `SessionManager.getClienteId()` implementado
- ✅ Solo falta que backend envíe los datos

**Documentación completa:** `documentacion/desarrollo-aqui/Solucion bloqueador clienteId.md`

### Cambios recientes implementados

**Fase 7 (Integración backend):**
✅ Login migrado a `/api/v1/usuarios/login` (antes `/auth/login`)  
✅ Perfil migrado a `/api/v1/usuarios/perfil` (antes `/api/v1/clientes/perfil`)  
✅ Parser de errores actualizado para campo `mensaje`  
✅ `GET /api/v1/clientes` (catálogo) integrado  

**Fase 8 (Features independientes):**
✅ Logout funcional (`POST /api/v1/usuarios/logout`)  
✅ Catálogo real habilitado por defecto  
✅ 6 nuevos tests (logout + catálogo)  

Ver `documentacion/desarrollo-aqui/Fase 7 - Especificacion integracion backend real.md` para el análisis completo.
