import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/foodly_colors.dart';
import 'theme/foodly_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

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
        RegisterScreen.routeName: (_) => const RegisterScreen(),
      },
    );
  }
}

