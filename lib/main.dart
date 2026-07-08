import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/navigation/foodly_deep_link_listener.dart';
import 'core/navigation/foodly_page_route.dart';
import 'theme/foodly_colors.dart';
import 'theme/foodly_theme.dart';
import 'domain/cart/cart_notifier.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'data/models/pedido_response_model.dart';
import 'screens/app_shell.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/local_detail_screen.dart';
import 'screens/main_screen.dart';
import 'screens/platos_search_screen.dart';
import 'screens/order_status_screen.dart';
import 'screens/register_screen.dart';
import 'screens/activate_account_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/confirm_email_change_screen.dart';
import 'widgets/auth_gate.dart';
import 'data/models/cliente_profile_model.dart';

Future<void> bootstrapFoodlyApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CartNotifier.instance.restore();
}

void main() {
  bootstrapFoodlyApp().then((_) => runApp(const FoodlyApp()));
}

class FoodlyApp extends StatelessWidget {
  const FoodlyApp({super.key});

  static final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return FoodlyDeepLinkListener(
      navigatorKey: _navigatorKey,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
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
      ),
    );
  }

  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case HomeScreen.routeName:
        return FoodlyPageRoute(page: const HomeScreen(), settings: settings);
      case LoginScreen.routeName:
        return FoodlyPageRoute(
          page: LoginScreen(
            successMessage: settings.arguments is String
                ? settings.arguments as String
                : null,
          ),
          settings: settings,
        );
      case RegisterScreen.routeName:
        return FoodlyPageRoute(
          page: const RegisterScreen(),
          settings: settings,
        );
      case ForgotPasswordScreen.routeName:
        return FoodlyPageRoute(
          page: const ForgotPasswordScreen(),
          settings: settings,
        );
      case ConfirmEmailChangeScreen.routeName:
        final emailToken = settings.arguments;
        return FoodlyPageRoute(
          page: ConfirmEmailChangeScreen(
            token: emailToken is String ? emailToken : '',
          ),
          settings: settings,
        );
      case ResetPasswordScreen.routeName:
        final token = settings.arguments;
        return FoodlyPageRoute(
          page: ResetPasswordScreen(
            token: token is String ? token : '',
          ),
          settings: settings,
        );
      case ActivateAccountScreen.routeName:
        final email = settings.arguments;
        return FoodlyPageRoute(
          page: ActivateAccountScreen(
            initialEmail: email is String ? email : '',
          ),
          settings: settings,
        );
      case EditProfileScreen.routeName:
        final profile = settings.arguments;
        if (profile is! ClienteProfileModel) {
          return FoodlyPageRoute(
            page: const Scaffold(
              body: Center(child: Text('Perfil no disponible.')),
            ),
            settings: settings,
          );
        }
        return FoodlyPageRoute(
          page: AuthGate(child: EditProfileScreen(profile: profile)),
          settings: settings,
        );
      case ChangePasswordScreen.routeName:
        return FoodlyPageRoute(
          page: const AuthGate(child: ChangePasswordScreen()),
          settings: settings,
        );
      case MainScreen.routeName:
        final initialTab = settings.arguments;
        return FoodlyPageRoute(
          page: AuthGate(
            child: AppShell(
              initialIndex: initialTab is int ? initialTab : 0,
            ),
          ),
          settings: settings,
        );
      case CartScreen.routeName:
        return FoodlyPageRoute(
          page: const AuthGate(child: CartScreen()),
          settings: settings,
        );
      case CheckoutScreen.routeName:
        return FoodlyPageRoute(
          page: const AuthGate(child: CheckoutScreen()),
          settings: settings,
        );
      case LocalDetailScreen.routeName:
        final localId = settings.arguments;
        if (localId is! int) {
          return FoodlyPageRoute(
            page: const Scaffold(
              body: Center(child: Text('Local no especificado.')),
            ),
            settings: settings,
          );
        }
        return FoodlyPageRoute(
          page: AuthGate(child: LocalDetailScreen(localId: localId)),
          settings: settings,
        );
      case PlatosSearchScreen.routeName:
        return FoodlyPageRoute(
          page: const AuthGate(child: PlatosSearchScreen()),
          settings: settings,
        );
      case OrderStatusScreen.routeName:
        final pedido = settings.arguments;
        if (pedido is! PedidoResponseModel) {
          return FoodlyPageRoute(
            page: const Scaffold(
              body: Center(child: Text('Pedido no disponible.')),
            ),
            settings: settings,
          );
        }
        return FoodlyPageRoute(
          page: AuthGate(child: OrderStatusScreen(pedido: pedido)),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
