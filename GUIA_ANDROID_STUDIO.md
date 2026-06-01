# Guía: compilar y ejecutar Foodly Mobile en Android Studio

Esta guía explica cómo abrir, compilar y ejecutar la app Flutter **foodly_mobile** en un dispositivo Android (emulador o celular físico) usando Android Studio.

---

## Requisitos previos

Antes de empezar, verificá que tengas instalado:

1. **Flutter SDK** (en esta máquina: `C:\Users\fedca\flutter`)
2. **Android Studio** (versión reciente)
3. Plugins de Android Studio:
   - **Flutter**
   - **Dart**

Para comprobar que Flutter está bien configurado, abrí una terminal y ejecutá:

```powershell
flutter doctor
```

Deberías ver ✓ en **Flutter** y **Android toolchain**. Si hay licencias pendientes:

```powershell
flutter doctor --android-licenses
```

Escribí `y` para aceptar cada una.

---

## Paso 1 — Abrir el proyecto correcto

1. Abrí **Android Studio**
2. Elegí **Open**
3. Seleccioná esta carpeta (no la carpeta padre `ProyectoMobile`):

   ```
   c:\Users\fedca\OneDrive\Desktop\Proyectos\ProyectoMobile\foodly_mobile
   ```

4. Confirmá con **OK**
5. Esperá a que Android Studio indexe el proyecto

> **Importante:** el proyecto Flutter es `foodly_mobile`. Si abrís `ProyectoMobile`, Android Studio no lo reconocerá como app Flutter.

---

## Paso 2 — Configurar Flutter SDK (solo la primera vez)

Si Android Studio no detecta Flutter:

1. **File → Settings → Languages & Frameworks → Flutter**
2. En **Flutter SDK path**, seleccioná: `C:\Users\fedca\flutter`
3. Aplicá los cambios y reiniciá Android Studio si te lo pide

---

## Paso 3 — Instalar dependencias del proyecto

En la terminal integrada de Android Studio (o PowerShell):

```powershell
cd "c:\Users\fedca\OneDrive\Desktop\Proyectos\ProyectoMobile\foodly_mobile"
flutter pub get
```

---

## Paso 4 — Preparar un dispositivo Android

Abrir el emulador **no instala la app**. Solo prepara el dispositivo donde se va a ejecutar.

### Opción A: Emulador (recomendado)

1. En Android Studio: **Tools → Device Manager**
2. Buscá el emulador **Pixel 9** (u otro que tengas creado)
3. Tocá el botón **Play** ▶
4. Esperá 1–2 minutos hasta que arranque por completo

También podés iniciarlo desde terminal:

```powershell
flutter emulators
flutter emulators --launch Pixel_9
```

Verificá que el emulador esté detectado:

```powershell
flutter devices
```

Deberías ver algo como:

```
sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64 • Android 16 (emulator)
```

### Opción B: Celular físico

1. En el teléfono: activá **Opciones de desarrollador**
2. Activá **Depuración USB**
3. Conectá el celular por USB
4. Aceptá el permiso de depuración en el teléfono
5. Ejecutá `flutter devices` y verificá que aparezca tu dispositivo

---

## Paso 5 — Seleccionar el dispositivo en Android Studio

1. Arriba, junto al botón **Run** ▶, abrí el selector de dispositivos
2. Elegí el emulador o celular Android (por ejemplo **Pixel 9** o **emulator-5554**)
3. **No elijas** `Windows (desktop)` si querés probar en Android

Si solo ves **Windows** o **Edge**, significa que no hay un dispositivo Android activo. Volvé al Paso 4.

---

## Paso 6 — Ejecutar la app

1. Verificá que el archivo de entrada sea **`lib/main.dart`**
2. Tocá **Run** ▶ (o **Shift + F10**)

Android Studio va a:

1. Compilar el proyecto con Gradle
2. Generar el APK
3. Instalarlo en el emulador/celular
4. Abrir la app automáticamente

### Primera compilación

La **primera vez** puede tardar **5–10 minutos** porque Gradle descarga:

- Android SDK Platform
- Build Tools
- NDK
- CMake

Es normal. Las siguientes ejecuciones serán mucho más rápidas.

---

## Paso 7 — Ejecutar desde terminal (alternativa)

Si el botón Run de Android Studio falla, podés usar la terminal:

```powershell
cd "c:\Users\fedca\OneDrive\Desktop\Proyectos\ProyectoMobile\foodly_mobile"
flutter run -d emulator-5554
```

Para listar dispositivos disponibles:

```powershell
flutter devices
```

Para ejecutar en el único dispositivo conectado:

```powershell
flutter run
```

### Comandos útiles mientras la app corre

| Tecla | Acción |
|-------|--------|
| `r` | Hot reload (recargar cambios) |
| `R` | Hot restart (reiniciar app) |
| `q` | Cerrar la app |

---

## Solución de problemas frecuentes

### Solo aparece "Windows (desktop)" en el selector

**Causa:** no hay emulador encendido ni celular conectado.

**Solución:** iniciá el emulador desde **Device Manager** y esperá a que termine de arrancar. Luego ejecutá `flutter devices`.

---

### El emulador abre pero la app no aparece

**Causa:** abrir el emulador no instala la app; hay que ejecutar el proyecto.

**Solución:** seleccioná el emulador como dispositivo y tocá **Run** ▶, o usá `flutter run -d emulator-5554`.

---

### Error: `Building with plugins requires symlink support` (Windows desktop)

**Causa:** aplica solo si ejecutás en **Windows (desktop)**, no en Android.

**Solución para Windows desktop:**
1. Activá **Modo de desarrollador** en Windows
2. Ejecutá: `start ms-settings:developers`

Para Android **no necesitás** este paso.

---

### Error de toolbar / `GoogleLoginAction` en Android Studio

**Causa:** bug interno del IDE, no del proyecto Flutter.

**Solución:**
1. Ejecutá la app desde terminal con `flutter run`
2. O desactivá temporalmente el plugin **Google Cloud Tools** en **Settings → Plugins**
3. O usá **File → Invalidate Caches → Invalidate and Restart**

---

### `flutter doctor` muestra licencias Android pendientes

```powershell
flutter doctor --android-licenses
```

---

### Gradle tarda mucho o falla

Probá limpiar y volver a compilar:

```powershell
cd "c:\Users\fedca\OneDrive\Desktop\Proyectos\ProyectoMobile\foodly_mobile"
flutter clean
flutter pub get
flutter run -d emulator-5554
```

---

## Resumen rápido

```
1. Abrir carpeta foodly_mobile en Android Studio
2. flutter pub get
3. Encender emulador (Device Manager → Play)
4. Seleccionar emulador-5554 / Pixel 9 (no Windows)
5. Run ▶ en main.dart
```

---

## Estructura del proyecto

```
foodly_mobile/
├── lib/
│   ├── main.dart          → Punto de entrada
│   ├── screens/           → Home, Login, Register
│   ├── widgets/           → Componentes reutilizables
│   └── theme/             → Colores y tipografías
├── assets/images/         → Imágenes de la app
├── android/               → Configuración nativa Android
└── pubspec.yaml           → Dependencias Flutter
```

---

## Referencias

- [Documentación Flutter](https://docs.flutter.dev/)
- [Flutter: instalación en Windows](https://docs.flutter.dev/get-started/install/windows)
- [Android Studio Device Manager](https://developer.android.com/studio/run/managing-avds)
