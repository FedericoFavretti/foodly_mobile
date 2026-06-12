import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/foodly_colors.dart';
import 'theme/foodly_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'data/models/pedido_response_model.dart';
import 'screens/app_shell.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/local_detail_screen.dart';
import 'screens/main_screen.dart';
import 'screens/order_status_screen.dart';
import 'screens/register_screen.dart';
import 'widgets/auth_gate.dart';

void main() {
  runApp(const FoodlyApp());
}

class FoodlyApp extends StatelessWidget {
  const FoodlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foodly',
      debugShowCheckedModeBanner: false,
      theme: FoodlyTheme.light.copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: FoodlyColors.blanco,
          hintStyle: GoogleFonts.nunito(
            color: FoodlyColors.grisIntermedio,
            fontSize: 15,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: FoodlyColors.negro,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: FoodlyColors.negro,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: FoodlyColors.celeste,
              width: 2,
            ),
          ),
        ),
      ),
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (_) => const HomeScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        MainScreen.routeName: (_) => const AuthGate(child: AppShell()),
        LocalDetailScreen.routeName: (_) => const AuthGate(
              child: _LocalDetailRoute(),
            ),
        CartScreen.routeName: (_) => const AuthGate(child: CartScreen()),
        CheckoutScreen.routeName: (_) => const AuthGate(child: CheckoutScreen()),
        OrderStatusScreen.routeName: (_) => const AuthGate(
              child: _OrderStatusRoute(),
            ),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
      },
    );
  }
}

class _LocalDetailRoute extends StatelessWidget {
  const _LocalDetailRoute();

  @override
  Widget build(BuildContext context) {
    final localId = ModalRoute.of(context)?.settings.arguments;
    if (localId is! int) {
      return const Scaffold(
        body: Center(child: Text('Local no especificado.')),
      );
    }
    return LocalDetailScreen(localId: localId);
  }
}

class _OrderStatusRoute extends StatelessWidget {
  const _OrderStatusRoute();

  @override
  Widget build(BuildContext context) {
    final pedido = ModalRoute.of(context)?.settings.arguments;
    if (pedido is! PedidoResponseModel) {
      return const Scaffold(
        body: Center(child: Text('Pedido no disponible.')),
      );
    }
    return OrderStatusScreen(pedido: pedido);
  }
}

