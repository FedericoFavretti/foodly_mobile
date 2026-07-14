# Crea las configuraciones de ejecucion de Android Studio para el proyecto Foodly Mobile.
# Ejecutar una sola vez luego de clonar el repo:
#   powershell -ExecutionPolicy Bypass -File .\setup_android_studio.ps1

$dir = ".idea\runConfigurations"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

# --- Foodly dev (Railway test) ---
$railway = @'
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Foodly dev (Railway test)" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="additionalArgs" value="--dart-define=GOOGLE_SERVER_CLIENT_ID=1072360825042-svvpngeddntj3jkeo3fmopahj9h1c29d.apps.googleusercontent.com --dart-define=API_BASE_URL=https://proyectoequipo32026-test.up.railway.app" />
    <option name="filePath" value="$PROJECT_DIR$/lib/main.dart" />
    <method v="2" />
  </configuration>
</component>
'@
Set-Content -Path "$dir\Foodly_dev_Railway.xml" -Value $railway -Encoding UTF8
Write-Host "[OK] Foodly dev (Railway test)" -ForegroundColor Green

# --- Foodly dev (localhost) ---
$localhost = @'
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Foodly dev (localhost)" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="additionalArgs" value="--dart-define=GOOGLE_SERVER_CLIENT_ID=1072360825042-svvpngeddntj3jkeo3fmopahj9h1c29d.apps.googleusercontent.com --dart-define=API_BASE_URL=http://10.0.2.2:8080" />
    <option name="filePath" value="$PROJECT_DIR$/lib/main.dart" />
    <method v="2" />
  </configuration>
</component>
'@
Set-Content -Path "$dir\Foodly_dev_localhost.xml" -Value $localhost -Encoding UTF8
Write-Host "[OK] Foodly dev (localhost)" -ForegroundColor Green

Write-Host ""
Write-Host "Listo. Reinicia Android Studio y las configuraciones apareceran en el menu de run." -ForegroundColor Cyan
