$tests = @(
  @{ archivo = "test/widget_test.dart";                    nombre = "Pantalla principal (Home)" },
  @{ archivo = "test/auth_repository_test.dart";           nombre = "Autenticacion (Login / Google)" },
  @{ archivo = "test/account_repository_test.dart";        nombre = "Cuenta (recuperar passwd, cambio correo)" },
  @{ archivo = "test/biometric_service_test.dart";         nombre = "Biometria (huella / Face ID)" },
  @{ archivo = "test/jwt_decoder_test.dart";               nombre = "JWT Decoder (token y roles)" },
  @{ archivo = "test/form_validators_test.dart";           nombre = "Validaciones de formularios" },
  @{ archivo = "test/cart_notifier_test.dart";             nombre = "Carrito de compras" },
  @{ archivo = "test/cart_storage_test.dart";              nombre = "Persistencia del carrito" },
  @{ archivo = "test/catalog_test.dart";                   nombre = "Catalogo de locales y platos" },
  @{ archivo = "test/pedido_model_test.dart";              nombre = "Modelo de pedido" },
  @{ archivo = "test/pedido_repository_test.dart";         nombre = "Repositorio de pedidos" },
  @{ archivo = "test/historial_test.dart";                 nombre = "Historial de pedidos" },
  @{ archivo = "test/calificacion_test.dart";              nombre = "Calificaciones" },
  @{ archivo = "test/reclamo_test.dart";                   nombre = "Reclamos" },
  @{ archivo = "test/cliente_profile_test.dart";           nombre = "Perfil del cliente" },
  @{ archivo = "test/cliente_repository_delete_test.dart"; nombre = "Eliminar cuenta" },
  @{ archivo = "test/logout_test.dart";                    nombre = "Logout" },
  @{ archivo = "test/profile_navigation_test.dart";        nombre = "Navegacion de perfil" },
  @{ archivo = "test/foodly_deep_link_parser_test.dart";   nombre = "Deep links (Mercado Pago)" }
)

Write-Host ""
Write-Host "  Ejecutando tests, aguarda..." -ForegroundColor Yellow
Write-Host ""

$totalPasados = 0
$totalFallidos = 0
$resultados = [System.Collections.Generic.List[object]]::new()

foreach ($t in $tests) {
  $output = flutter test $t.archivo --reporter compact 2>&1 | Out-String

  $allPlus  = [regex]::Matches($output, '\+(\d+):')
  $allMinus = [regex]::Matches($output, '-(\d+):')

  $pasados  = 0
  $fallidos = 0
  if ($allPlus.Count  -gt 0) { $pasados  = [int]$allPlus[$allPlus.Count   - 1].Groups[1].Value }
  if ($allMinus.Count -gt 0) { $fallidos = [int]$allMinus[$allMinus.Count  - 1].Groups[1].Value }

  $totalPasados  += $pasados
  $totalFallidos += $fallidos

  $resultados.Add(@{ nombre = $t.nombre; pasados = $pasados; fallidos = $fallidos })
}

# Mostrar todo junto al final para captura de pantalla limpia
Clear-Host

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  FOODLY MOBILE - SUITE DE TESTS UNITARIOS     " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

$i = 1
foreach ($r in $resultados) {
  $num = $i.ToString().PadLeft(2)
  if ($r.fallidos -eq 0) {
    Write-Host ("  " + $num + ".  [PASO]  " + $r.nombre + "  (" + $r.pasados + " tests)") -ForegroundColor Green
  } else {
    Write-Host ("  " + $num + ".  [FALLO] " + $r.nombre + "  (" + $r.fallidos + " fallidos)") -ForegroundColor Red
  }
  $i++
}

Write-Host ""
Write-Host "------------------------------------------------" -ForegroundColor Cyan
if ($totalFallidos -eq 0) {
  Write-Host ("  RESULTADO FINAL: " + $totalPasados + " tests pasados - TODOS OK") -ForegroundColor Green
} else {
  Write-Host ("  RESULTADO FINAL: " + $totalPasados + " pasados / " + $totalFallidos + " fallidos") -ForegroundColor Red
}
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
