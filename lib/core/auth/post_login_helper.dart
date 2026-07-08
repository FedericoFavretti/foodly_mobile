import 'package:flutter/material.dart';

import 'biometric_service.dart';
import '../../domain/session/session_manager.dart';

/// Ofrece activar biometría tras el primer login exitoso (email o Google).
Future<void> offerBiometricIfNeeded(
  BuildContext context,
  BiometricService biometricService,
) async {
  final alreadyDecided = await SessionManager.getBiometricEnabled();
  if (alreadyDecided != null) return;

  final available = await biometricService.isAvailable();
  if (!available || !context.mounted) return;

  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Acceso rápido'),
      content: const Text(
        '¿Querés usar tu huella digital o Face ID para ingresar más rápido la próxima vez?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Ahora no'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Activar'),
        ),
      ],
    ),
  );

  await SessionManager.setBiometricEnabled(accepted ?? false);
}
