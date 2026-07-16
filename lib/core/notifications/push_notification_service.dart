import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';

/// Canal Android para notificaciones de Foodly.
const _androidChannel = AndroidNotificationChannel(
  'foodly_channel',
  'Foodly',
  description: 'Notificaciones de pedidos y reclamos de Foodly.',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Handler top-level para mensajes recibidos con la app en background/cerrada.
/// Debe ser una función de nivel superior (no método de clase).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase ya está inicializado en este isolate por el plugin.
  // Solo logueamos; las notificaciones de sistema las muestra FCM automáticamente.
  if (kDebugMode) {
    print('[FCM Background] ${message.messageId} — ${message.notification?.title}');
  }
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _api = ApiClient();
  String? _currentToken;
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Inicializa FCM, permisos, canal Android y escuchadores.
  /// Llamar una vez tras login exitoso.
  /// Es seguro llamar múltiples veces; solo se inicializa una vez.
  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    // Si ya está inicializado o inicializándose, no hacer nada
    if (_isInitialized || _isInitializing) {
      if (kDebugMode) {
        print('[FCM] Ya inicializado o en proceso de inicialización.');
      }
      return;
    }

    _isInitializing = true;

    try {
      // Registrar handler de background
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Permisos (iOS + Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Canal Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Inicializar plugin de notificaciones locales
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _navegarSegunPayload(details.payload, navigatorKey);
      },
    );

    // Obtener y registrar token
    await _refreshToken();

    // Renovación automática de token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      _currentToken = newToken;
      await _registrarEnBackend(newToken);
    });

    // Mensajes en foreground → mostrar notificación local
    FirebaseMessaging.onMessage.listen((message) {
      _mostrarNotificacionLocal(message);
    });

    // Tap cuando la app estaba en background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _manejarTap(message, navigatorKey);
    });

      // Tap cuando la app estaba cerrada
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        // Esperar a que el navigator esté montado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _manejarTap(initialMessage, navigatorKey);
        });
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('[FCM] Inicialización completada exitosamente.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error durante inicialización: $e');
      }
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Elimina el token actual del backend (llamar antes del logout).
  Future<void> eliminarToken() async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('[FCM] No inicializado, nada que eliminar.');
      }
      return;
    }

    try {
      final token = _currentToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _api.delete(
          ApiConstants.notificacionTokenEndpoint,
          requiresAuth: true,
          body: {'token': token},
        );
      }
      await FirebaseMessaging.instance.deleteToken();
      _currentToken = null;
      if (kDebugMode) {
        print('[FCM] Token eliminado del backend y del dispositivo.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error eliminando token: $e');
      }
    }
  }

  Future<void> _refreshToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      _currentToken = token;
      await _registrarEnBackend(token);
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error obteniendo token: $e');
      }
    }
  }

  Future<void> _registrarEnBackend(String token) async {
    try {
      await _api.post(
        ApiConstants.notificacionTokenEndpoint,
        {
          'token': token,
          'plataforma': Platform.isAndroid ? 'ANDROID' : 'IOS',
        },
        requiresAuth: true,
      );
      if (kDebugMode) {
        print('[FCM] Token registrado en backend.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error registrando token en backend: $e');
      }
    }
  }

  void _mostrarNotificacionLocal(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final payload = jsonEncode(message.data);

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  void _manejarTap(RemoteMessage message, GlobalKey<NavigatorState> navigatorKey) {
    _navegarSegunPayload(jsonEncode(message.data), navigatorKey);
  }

  void _navegarSegunPayload(String? payload, GlobalKey<NavigatorState> navigatorKey) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final tipo = data['tipo'] as String?;
      final pedidoIdStr = data['pedidoId'] as String?;

      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      switch (tipo) {
        case 'pedido_confirmado':
        case 'pedido_rechazado':
        case 'factura_generada':
          // Validar que pedidoId sea un número válido
          final pedidoId = pedidoIdStr != null ? int.tryParse(pedidoIdStr) : null;
          if (pedidoId == null || pedidoId <= 0) {
            if (kDebugMode) {
              print('[FCM] pedidoId inválido: $pedidoIdStr');
            }
            return;
          }
          // Navegar a historial (tab 1 del AppShell)
          navigator.pushNamedAndRemoveUntil(
            '/main',
            (route) => false,
            arguments: 1,
          );
        default:
          if (kDebugMode) {
            print('[FCM] Tipo de notificación desconocido: $tipo');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error parseando payload: $e');
      }
    }
  }
}
