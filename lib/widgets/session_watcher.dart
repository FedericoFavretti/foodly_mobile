import 'dart:async';

import 'package:flutter/material.dart';

import '../core/auth/jwt_decoder.dart';
import '../domain/session/session_manager.dart';
import '../screens/login_screen.dart';

/// Vigila expiración del JWT y redirige a login (equivalente web `SessionWatcher`).
class SessionWatcher extends StatefulWidget {
  const SessionWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<SessionWatcher> createState() => _SessionWatcherState();
}

class _SessionWatcherState extends State<SessionWatcher>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _redirecting = false;

  static const _sessionExpiredMessage =
      'Tu sesión expiró. Por favor iniciá sesión nuevamente.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkSession(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSession();
    }
  }

  Future<void> _checkSession() async {
    if (_redirecting || !mounted) return;

    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) return;
    if (!JwtDecoder.isExpired(token)) return;

    _redirecting = true;
    await SessionManager.clearSession();
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (_) => false,
      arguments: _sessionExpiredMessage,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
