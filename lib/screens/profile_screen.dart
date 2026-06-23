import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/errors/api_exception.dart';
import '../data/models/cliente_profile_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cliente_profile_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileRepository = ClienteProfileRepository();
  final _authRepository = AuthRepository();

  bool _isLoading = true;
  Object? _error;
  ClienteProfileModel? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _profileRepository.getOrFetch();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _data = data;
      });
    } on SessionExpiredException {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context, HomeScreen.routeName, (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  Future<void> _onRefresh() async {
    try {
      final data = await _profileRepository.getOrFetch();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (_) {}
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

  Widget _buildContent() {
    if (_isLoading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      final message = _error is ApiException
          ? (_error as ApiException).userMessage
          : 'No pudimos cargar tu perfil.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _load();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _data!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
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
      ],
    );
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
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildContent(),
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
