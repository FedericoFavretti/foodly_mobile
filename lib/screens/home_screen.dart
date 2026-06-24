import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/food_items.dart';
import '../data/how_it_works_steps.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/food_card.dart';
import '../widgets/foodly_button.dart';
import '../widgets/foodly_navbar.dart';
import '../widgets/step_card.dart';
import '../widgets/wavy_accent.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: FoodlyNavbar(
              onLoginTap: () => Navigator.pushNamed(context, '/login'),
            ),
          ),
          SliverToBoxAdapter(child: _HeroSection()),
          SliverToBoxAdapter(child: _MostOrderedSection()),
          SliverToBoxAdapter(child: _HowItWorksSection()),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: FoodlyColors.celeste,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        children: [
          Image.asset(
            'assets/images/burger.png',
            height: 220,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Miles de sabores.\nUn solo lugar.',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 34,
                height: 1.15,
                color: FoodlyColors.blanco,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Todas las comidas, a un clic de distancia',
              style: FoodlyTheme.sansBold.copyWith(
                fontSize: 18,
                color: FoodlyColors.amarillo,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FoodlyButton(
            label: 'ORDENA AHORA',
            variant: FoodlyButtonVariant.outline,
            onPressed: () => Navigator.pushNamed(context, LoginScreen.routeName),
          ),
        ],
      ),
    );
  }
}

class _MostOrderedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lo más pedido, directo a tu casa',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 26,
              color: FoodlyColors.grisOscuro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Descubrí los platos que todos eligen y pedí fácil, rápido y seguro.',
            style: GoogleFonts.nunito(
              fontSize: 15,
              height: 1.4,
              color: FoodlyColors.grisIntermedio,
            ),
          ),
          const SizedBox(height: 12),
          const WavyAccent(),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemCount: foodItems.length,
              itemBuilder: (context, index) {
                return FoodCard(item: foodItems[index]);
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FoodlyButton(
              label: 'OTRAS OPCIONES',
              variant: FoodlyButtonVariant.outline,
              onPressed: () => Navigator.pushNamed(context, LoginScreen.routeName),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: FoodlyColors.grisClaro,
      padding: const EdgeInsets.fromLTRB(16, 32, 0, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo funciona?',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 26,
              color: FoodlyColors.grisOscuro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pedir tu comida en solo 3 pasos.',
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: FoodlyColors.grisIntermedio,
            ),
          ),
          const SizedBox(height: 12),
          const WavyAccent(),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemCount: howItWorksSteps.length,
              itemBuilder: (context, index) {
                return StepCard(step: howItWorksSteps[index]);
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FoodlyButton(
              label: 'ORDENA AHORA',
              onPressed: () => Navigator.pushNamed(context, LoginScreen.routeName),
            ),
          ),
        ],
      ),
    );
  }
}
