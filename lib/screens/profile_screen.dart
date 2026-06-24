import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/errors/api_exception.dart';
import '../data/models/cliente_profile_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cliente_profile_repository.dart';
import '../data/repositories/cliente_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileRepository = ClienteProfileRepository();
  final _authRepository = AuthRepository();
  final _clienteRepository = ClienteRepository();
  late Future<ClienteProfileModel> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileRepository.getOrFetch();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que querés cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _authRepository.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      HomeScreen.routeName,
      (_) => false,
    );
  }

  Future<void> _deleteAccount(ClienteProfileModel profile) async {
    // Paso 1: advertencia
    final step1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Esta acción es permanente e irreversible. '
          'Todos tus datos, historial de pedidos y calificaciones serán eliminados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (step1 != true || !mounted) return;

    // Paso 2: confirmar con email
    final emailController = TextEditingController();
    final step2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escribí tu correo electrónico para confirmar:',
              style: GoogleFonts.nunito(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'tu@email.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (emailController.text.trim().toLowerCase() !=
                  profile.email.toLowerCase()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El correo no coincide con tu cuenta.'),
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Eliminar mi cuenta'),
          ),
        ],
      ),
    );

    if (step2 != true || !mounted) return;

    try {
      await _clienteRepository.eliminarCuenta();
      if (!mounted) return;
      await _authRepository.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeScreen.routeName,
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.userMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mi perfil',
          style: FoodlyTheme.serifTitle.copyWith(fontSize: 22),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: FoodlyColors.blanco,
        foregroundColor: FoodlyColors.grisOscuro,
        elevation: 0,
      ),
      body: FutureBuilder<ClienteProfileModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ProfileHeaderSkeleton(),
            );
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).userMessage
                : 'No pudimos cargar tu perfil.';
            return ErrorState(
              message: message,
              onRetry: () => setState(() {
                _profileFuture = _profileRepository.getOrFetch();
              }),
            );
          }

          final profile = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileHeader(profile: profile),
              const SizedBox(height: 24),
              _InfoTile(
                icon: Icons.email_outlined,
                label: 'Correo electrónico',
                value: profile.email,
              ),
              if (profile.direccion != null) ...[
                const SizedBox(height: 12),
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Dirección',
                  value: profile.direccion!.resumen,
                ),
              ],
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Cuenta'),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Color(0xFFD32F2F),
                ),
                title: Text(
                  'Cerrar sesión',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD32F2F),
                  ),
                ),
                onTap: _logout,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: Color(0xFFD32F2F),
                ),
                title: Text(
                  'Eliminar cuenta',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD32F2F),
                  ),
                ),
                subtitle: Text(
                  'Acción irreversible',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: FoodlyColors.grisIntermedio,
                  ),
                ),
                onTap: () => _deleteAccount(profile),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final ClienteProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final initials =
        '${profile.nombre.isNotEmpty ? profile.nombre[0] : ''}${profile.apellido.isNotEmpty ? profile.apellido[0] : ''}'
            .toUpperCase();

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: FoodlyColors.celeste,
          child: Text(
            initials,
            style: FoodlyTheme.sansBlack.copyWith(
              fontSize: 28,
              color: FoodlyColors.blanco,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${profile.nombre} ${profile.apellido}',
          style: FoodlyTheme.serifTitle.copyWith(fontSize: 24),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: FoodlyColors.grisIntermedio),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: FoodlyTheme.sansBlack.copyWith(
        fontSize: 16,
        color: FoodlyColors.grisOscuro,
      ),
    );
  }
}
