import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'foodly_colors.dart';

abstract final class FoodlyTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: FoodlyColors.celeste,
        primary: FoodlyColors.celeste,
        secondary: FoodlyColors.amarillo,
        surface: FoodlyColors.blanco,
      ),
      scaffoldBackgroundColor: FoodlyColors.blanco,
    );

    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: FoodlyColors.grisIntermedio,
        displayColor: FoodlyColors.grisOscuro,
      ),
    );
  }

  static TextStyle get serifTitle => GoogleFonts.dmSerifDisplay(
        color: FoodlyColors.celeste,
        fontSize: 32,
        height: 1.15,
      );

  static TextStyle get serifSection => GoogleFonts.dmSerifDisplay(
        color: FoodlyColors.grisOscuro,
        fontSize: 22,
        height: 1.25,
      );

  static TextStyle get sansBold => GoogleFonts.nunito(
        fontWeight: FontWeight.w800,
      );

  static TextStyle get sansBlack => GoogleFonts.nunito(
        fontWeight: FontWeight.w900,
      );
}
