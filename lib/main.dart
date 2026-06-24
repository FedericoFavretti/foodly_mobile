import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/navigation/foodly_page_route.dart';
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
      onGenerateRoute: _generateRoute,
    );
  }

  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    Widget page;

    switch (settings.name) {
      case HomeScreen.routeName:
        page = const HomeScreen();
      case LoginScreen.routeName:
        page = const LoginScreen();
      case RegisterScreen.routeName:
        page = const RegisterScreen();
      case MainScreen.routeName:
        page = const AuthGate(child: AppShell());
      case CartScreen.routeName:
        page = const AuthGate(child: CartScreen());
      case CheckoutScreen.routeName:
        page = const AuthGate(child: CheckoutScreen());
      case LocalDetailScreen.routeName:
        final localId = settings.arguments;
        if (localId is! int) {
          page = const Scaffold(
            body: Center(child: Text('Local no especificado.')),
          );
        } else {
          page = AuthGate(child: LocalDetailScreen(localId: localId));
        }
      case OrderStatusScreen.routeName:
        final pedido = settings.arguments;
        if (pedido is! PedidoResponseModel) {
          page = const Scaffold(
            body: Center(child: Text('Pedido no disponible.')),
          );
        } else {
          page = AuthGate(child: OrderStatusScreen(pedido: pedido));
        }
      default:
        return null;
    }

    return FoodlyPageRoute(page: page, settings: settings);
  }
}
