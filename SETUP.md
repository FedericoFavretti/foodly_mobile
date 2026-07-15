# Foodly Mobile — Guía de configuración

## 1. Compilar con variables de entorno

La app usa `--dart-define` en lugar de un `.env`. El archivo `.vscode/launch.json` ya tiene las configuraciones listas para VS Code / Cursor. Para compilar por CLI:

```bash
flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=1072360825042-svvpngeddntj3jkeo3fmopahj9h1c29d.apps.googleusercontent.com \
  --dart-define=API_BASE_URL=https://proyectoequipo32026-test.up.railway.app
```

---

## 2. Google Sign-In en Android — google-services.json (OBLIGATORIO)

Sin este archivo el botón "Continuar con Google" falla en runtime.

### Pasos:
1. Ir a [Firebase Console](https://console.firebase.google.com) → proyecto Foodly (o crear uno nuevo).
2. **Agregar app Android** con el `applicationId` del proyecto:
   - Abrir `android/app/build.gradle` → buscar `applicationId` (ej: `com.example.foodly_mobile`)
3. Descargar `google-services.json`.
4. Colocar el archivo en **`android/app/google-services.json`** (ya está en `.gitignore`).

### SHA-1 del keystore de debug (para que Google lo acepte):
```bash
# Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Mac/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```
Agregar el SHA-1 resultante en Firebase Console → App → Huella digital.

---

## 3. Mercado Pago deep links — Configuración en Railway (pendiente backend)

Las URLs de retorno de MP actualmente apuntan al frontend web. Para que el retorno llegue al app mobile hay que:

### A) Agregar variables en Railway (backend):
```
MP_MOBILE_SUCCESS_URL=foodly://payment/success
MP_MOBILE_FAILURE_URL=foodly://payment/failure
MP_MOBILE_PENDING_URL=foodly://payment/pending
```

### B) Cambiar en el backend (`PedidoController` / `MercadoPagoService`):
Detectar el header `X-Foodly-Client: mobile` (que ya envía el app) y usar las URLs mobile:

```java
// Ejemplo Java Spring
String clientType = request.getHeader("X-Foodly-Client");
boolean isMobile = "mobile".equals(clientType);

String successUrl = isMobile ? mpMobileSuccessUrl : mpSuccessUrl;
String failureUrl = isMobile ? mpMobileFailureUrl : mpFailureUrl;
String pendingUrl = isMobile ? mpMobilePendingUrl : mpPendingUrl;
```

### C) El listener en mobile ya está implementado:
- `AndroidManifest.xml` → `intent-filter` para `foodly://payment`
- `FoodlyDeepLinkListener` en `main.dart` → escucha y navega al tab Pedidos

---

## 4. Biometría

Funciona automáticamente. El flujo es:
1. Usuario hace login (email o Google) por primera vez.
2. Aparece diálogo: "¿Activar huella / Face ID?"
3. Si acepta, en los próximos logins aparece el botón de biometría.

No requiere configuración adicional. Los permisos ya están en `AndroidManifest.xml`.

---

## 5. Checklist antes de release

- [ ] `android/app/google-services.json` presente
- [ ] SHA-1 del keystore de release registrado en Firebase
- [ ] Railway: variables `MP_MOBILE_*` configuradas
- [ ] Backend: lógica para usar URLs mobile según `X-Foodly-Client` header
- [ ] `API_BASE_URL` apunta al entorno correcto (test vs producción)
