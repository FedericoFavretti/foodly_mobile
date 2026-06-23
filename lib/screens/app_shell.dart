import 'package:flutter/material.dart';

import '../theme/foodly_colors.dart';
import '../widgets/cart_fab.dart';
import 'historial_screen.dart';
import 'main_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex = widget.initialIndex;
  late final Set<int> _loaded = {widget.initialIndex};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const MainScreen(),
          _loaded.contains(1) ? const HistorialScreen() : const SizedBox.shrink(),
          _loaded.contains(2) ? const ProfileScreen() : const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: const CartFab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() {
          _loaded.add(index);
          _currentIndex = index;
        }),
        selectedItemColor: FoodlyColors.celeste,
        unselectedItemColor: FoodlyColors.grisIntermedio,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Locales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Mis pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
