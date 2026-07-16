import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../core/notifications/push_notification_service.dart';
import '../core/providers/notificacion_notifier.dart';
import '../data/repositories/notificacion_repository.dart';
import '../theme/foodly_colors.dart';
import '../widgets/cart_fab.dart';
import '../widgets/session_watcher.dart';
import '../main.dart';
import 'historial_screen.dart';
import 'main_screen.dart';
import 'notificaciones_screen.dart';
import 'profile_screen.dart';
import 'reclamos_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late int _currentIndex;
  int _profileRefreshKey = 0;
  final _historialKey = GlobalKey<HistorialScreenState>();
  final _reclamosKey = GlobalKey<ReclamosScreenState>();
  late final NotificacionNotifier _notificacionNotifier;
  bool _firebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    WidgetsBinding.instance.addObserver(this);

    _notificacionNotifier = NotificacionNotifier(
      NotificacionRepository(ApiClient()),
    );
    _notificacionNotifier.startPolling();

    _initPush();
  }

  Future<void> _initPush() async {
    try {
      // Firebase se inicializa aquí (después del login) para no interferir
      // con el flujo de Credential Manager que usa Google Sign-In antes del login.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      // Re-habilitar la colección de datos ahora que el usuario ya inició sesión.
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      
      // Inicializar el servicio de notificaciones push
      await PushNotificationService.instance.initialize(
        navigatorKey: FoodlyApp.navigatorKey,
      );
      
      if (mounted) {
        setState(() {
          _firebaseInitialized = true;
        });
      }
      if (kDebugMode) {
        print('[Push] Firebase inicializado correctamente.');
      }
    } catch (e) {
      // Si Firebase no está configurado, las notificaciones push no funcionan
      // pero el resto de la app sigue operativa.
      if (kDebugMode) {
        print('[Push] Firebase no disponible: $e');
      }
      if (mounted) {
        setState(() {
          _firebaseInitialized = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificacionNotifier.startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _notificacionNotifier.stopPolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificacionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const MainScreen(),
      HistorialScreen(
        key: _historialKey,
        isTabActive: _currentIndex == 1,
        onExploreLocales: () => setState(() => _currentIndex = 0),
        onReclamoCreado: () {
          setState(() => _currentIndex = 2);
          _reclamosKey.currentState?.refresh(silent: true);
        },
      ),
      ReclamosScreen(
        key: _reclamosKey,
        onExploreLocales: () => setState(() => _currentIndex = 1),
      ),
      NotificacionesScreen(notifier: _notificacionNotifier),
      ProfileScreen(key: ValueKey(_profileRefreshKey)),
    ];

    return SessionWatcher(
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            for (var i = 0; i < screens.length; i++)
              IgnorePointer(
                ignoring: i != _currentIndex,
                child: TickerMode(
                  enabled: i == _currentIndex,
                  child: screens[i],
                ),
              ),
          ],
        ),
        floatingActionButton: _currentIndex == 0 ? CartFab() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: FoodlyColors.blanco,
            boxShadow: [
              BoxShadow(
                color: FoodlyColors.grisOscuro.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: ListenableBuilder(
              listenable: _notificacionNotifier,
              builder: (context, _) {
                final noLeidas = _notificacionNotifier.noLeidasCount;

                return NavigationBar(
                  elevation: 0,
                  height: 64,
                  backgroundColor: FoodlyColors.blanco,
                  indicatorColor: FoodlyColors.celeste.withValues(alpha: 0.15),
                  labelBehavior:
                      NavigationDestinationLabelBehavior.alwaysShow,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      if (index == 1) {
                        _historialKey.currentState?.refresh(silent: true);
                      }
                      if (index == 2) {
                        _reclamosKey.currentState?.refresh(silent: true);
                      }
                      if (index == 3) {
                        _notificacionNotifier.refresh();
                      }
                      if (index == 4) _profileRefreshKey++;
                      _currentIndex = index;
                    });
                  },
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.storefront_outlined),
                      selectedIcon: Icon(
                        Icons.storefront,
                        color: FoodlyColors.celeste,
                      ),
                      label: 'Locales',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(
                        Icons.receipt_long,
                        color: FoodlyColors.celeste,
                      ),
                      label: 'Pedidos',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.support_agent_outlined),
                      selectedIcon: Icon(
                        Icons.support_agent,
                        color: FoodlyColors.celeste,
                      ),
                      label: 'Reclamos',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: noLeidas > 0,
                        label: Text(
                          noLeidas > 9 ? '9+' : '$noLeidas',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        child:
                            const Icon(Icons.notifications_none_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: noLeidas > 0,
                        label: Text(
                          noLeidas > 9 ? '9+' : '$noLeidas',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        child: const Icon(
                          Icons.notifications,
                          color: FoodlyColors.celeste,
                        ),
                      ),
                      label: 'Avisos',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(
                        Icons.person,
                        color: FoodlyColors.celeste,
                      ),
                      label: 'Perfil',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
