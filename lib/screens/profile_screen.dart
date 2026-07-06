import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/auth/biometric_service.dart';
import '../core/errors/api_exception.dart';
import '../core/navigation/foodly_page_route.dart';
import '../data/models/calificacion_detalle_model.dart';
import '../data/models/calificacion_global_model.dart';
import '../data/models/cliente_profile_model.dart';
import '../domain/session/session_manager.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/calificacion_repository.dart';
import '../data/repositories/cliente_profile_repository.dart';
import '../data/repositories/cliente_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/client_rating_summary_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/wavy_accent.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.profileRepository});

  final ClienteProfileRepository? profileRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ClienteProfileRepository _profileRepository;
  final _authRepository = AuthRepository();
  final _clienteRepository = ClienteRepository();
  final _biometricService = LocalAuthBiometricService();
  late Future<ClienteProfileModel> _profileFuture;
  bool _isRefreshing = false;
  int _reputacionRefreshKey = 0;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _biometricLoading = false;

  @override
  void initState() {
    super.initState();
    _profileRepository =
        widget.profileRepository ?? ClienteProfileRepository();
    _profileFuture = _profileRepository.getOrFetch();
    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    final available = await _biometricService.isAvailable();
    final enabled = await SessionManager.getBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled == true;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_biometricLoading) return;
    setState(() => _biometricLoading = true);
    try {
      if (value) {
        final result = await _biometricService.authenticate();
        if (result != BiometricResult.success) {
          if (mounted) _showBiometricError(result);
          return;
        }
        await SessionManager.setBiometricEnabled(true);
      } else {
        await SessionManager.setBiometricEnabled(false);
      }
      if (mounted) setState(() => _biometricEnabled = value);
    } finally {
      if (mounted) setState(() => _biometricLoading = false);
    }
  }

  void _showBiometricError(BiometricResult result) {
    final message = switch (result) {
      BiometricResult.lockedOut =>
        'Demasiados intentos fallidos. Probá más tarde.',
      BiometricResult.notEnrolled =>
        'No hay biometría registrada en este dispositivo.',
      BiometricResult.unavailable =>
        'La biometría no está disponible en este dispositivo.',
      _ => 'No se pudo verificar tu identidad.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openChangeEmail(String currentEmail) async {
    await Navigator.of(context).push<void>(
      FoodlyPageRoute(
        settings: const RouteSettings(name: ChangeEmailScreen.routeName),
        page: ChangeEmailScreen(currentEmail: currentEmail),
      ),
    );
  }

  Future<void> _reloadProfile({bool silent = false}) async {
    if (silent) setState(() => _isRefreshing = true);
    setState(() {
      _profileFuture = _profileRepository.getOrFetch();
      _reputacionRefreshKey++;
    });
    try {
      await _profileFuture;
    } finally {
      if (mounted && silent) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _openEditProfile(ClienteProfileModel profile) async {
    final updated = await Navigator.of(context).push<ClienteProfileModel>(
      FoodlyPageRoute(
        settings: RouteSettings(
          name: EditProfileScreen.routeName,
          arguments: profile,
        ),
        page: EditProfileScreen(profile: profile),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _profileFuture = Future.value(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
    }
  }

  Future<void> _openChangePassword() async {
    final message = await Navigator.of(context).push<String>(
      FoodlyPageRoute(
        settings: const RouteSettings(
          name: ChangePasswordScreen.routeName,
        ),
        page: const ChangePasswordScreen(),
      ),
    );
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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

    emailController.dispose();

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
      backgroundColor: FoodlyColors.blanco,
      body: FutureBuilder<ClienteProfileModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const _ProfileLoadingView();
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).userMessage
                : 'No pudimos cargar tu perfil.';
            return Column(
              children: [
                const _ProfileHero(
                  displayName: 'Mi perfil',
                  email: '',
                  isRefreshing: false,
                ),
                Expanded(
                  child: ErrorState(
                    message: message,
                    onRetry: () => _reloadProfile(),
                  ),
                ),
              ],
            );
          }

          final profile = snapshot.data!;
          return Column(
            children: [
              _ProfileHero(
                displayName: _heroName(profile),
                email: profile.email,
                fotoUrl: profile.fotoUrl,
                initials: _initials(profile),
                isRefreshing: _isRefreshing,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: FoodlyColors.celeste,
                  onRefresh: () => _reloadProfile(silent: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 56, 16, 32),
                    children: [
                      _ProfileInfoCard(
                        title: 'Datos personales',
                        icon: Icons.badge_outlined,
                        trailing: TextButton.icon(
                          onPressed: () => _openEditProfile(profile),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: FoodlyColors.celeste,
                          ),
                          label: Text(
                            'Editar',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              color: FoodlyColors.celeste,
                            ),
                          ),
                        ),
                        children: [
                          _ProfileInfoRow(
                            icon: Icons.person_outline,
                            label: 'Nombre',
                            value: _displayValue(profile.nombre),
                          ),
                          _ProfileInfoRow(
                            icon: Icons.person_outline,
                            label: 'Apellido',
                            value: _displayValue(profile.apellido),
                          ),
                          _ProfileInfoRow(
                            icon: Icons.email_outlined,
                            label: 'Correo electrónico',
                            value: profile.email,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ProfileInfoCard(
                        title: 'Entrega',
                        icon: Icons.delivery_dining_outlined,
                        children: [
                          _ProfileInfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Dirección de entrega',
                            value: profile.direccion?.resumen.isNotEmpty == true
                                ? profile.direccion!.resumen
                                : 'Sin dirección registrada',
                            muted: profile.direccion?.resumen.isNotEmpty != true,
                          ),
                          if (profile.direccion?.codigoPostal?.isNotEmpty ==
                              true)
                            _ProfileInfoRow(
                              icon: Icons.markunread_mailbox_outlined,
                              label: 'Código postal',
                              value: profile.direccion!.codigoPostal!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ReputacionSection(
                        key: ValueKey(_reputacionRefreshKey),
                        clienteId: profile.id,
                      ),
                      const SizedBox(height: 16),
                      _ProfileInfoCard(
                        title: 'Cuenta',
                        icon: Icons.settings_outlined,
                        children: [
                          if (_biometricAvailable) ...[
                            _BiometricToggleRow(
                              value: _biometricEnabled,
                              loading: _biometricLoading,
                              onChanged: _toggleBiometric,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Divider(height: 1),
                            ),
                          ],
                          _ProfileActionRow(
                            icon: Icons.email_outlined,
                            title: 'Cambiar correo',
                            subtitle:
                                'Confirmación por enlace en tu correo actual',
                            color: FoodlyColors.celeste,
                            onTap: () => _openChangeEmail(profile.email),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Divider(height: 1),
                          ),
                          _ProfileActionRow(
                            icon: Icons.lock_outline_rounded,
                            title: 'Cambiar contraseña',
                            subtitle: 'Verificación por código en tu correo',
                            color: FoodlyColors.celeste,
                            onTap: _openChangePassword,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Divider(height: 1),
                          ),
                          _ProfileActionRow(
                            icon: Icons.logout_rounded,
                            title: 'Cerrar sesión',
                            subtitle: 'Salir de tu cuenta en este dispositivo',
                            color: FoodlyColors.celeste,
                            onTap: _logout,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Divider(height: 1),
                          ),
                          _ProfileActionRow(
                            icon: Icons.delete_forever_outlined,
                            title: 'Eliminar cuenta',
                            subtitle: 'Acción permanente e irreversible',
                            color: const Color(0xFFD32F2F),
                            onTap: () => _deleteAccount(profile),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Cliente Nº ${profile.id}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: FoodlyColors.grisIntermedio,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _displayValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }

  static String _heroName(ClienteProfileModel profile) {
    return profile.nombreCompleto.isNotEmpty
        ? profile.nombreCompleto
        : 'Mi perfil';
  }

  static String _initials(ClienteProfileModel profile) {
    final initialsSource = profile.nombreCompleto.isNotEmpty
        ? profile.nombreCompleto
        : profile.email;
    return initialsSource
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ColoredBox(
          color: FoodlyColors.celeste,
          child: SizedBox(
            height: MediaQuery.paddingOf(context).top + 160,
            width: double.infinity,
          ),
        ),
        const Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 56, 16, 32),
            child: ProfileScreenSkeleton(),
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayName,
    required this.email,
    required this.isRefreshing,
    this.fotoUrl,
    this.initials,
  });

  final String displayName;
  final String email;
  final String? fotoUrl;
  final String? initials;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ColoredBox(
          color: FoodlyColors.celeste,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 72),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mi perfil',
                            style: FoodlyTheme.sansBlack.copyWith(
                              fontSize: 30,
                              height: 1.05,
                              color: FoodlyColors.blanco,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            displayName,
                            style: FoodlyTheme.sansBold.copyWith(
                              fontSize: 15,
                              color: FoodlyColors.amarillo,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              email,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: FoodlyColors.blanco.withValues(
                                  alpha: 0.92,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isRefreshing)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: FoodlyColors.blanco,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: WavyAccent(),
                ),
              ),
              Container(
                height: 22,
                decoration: const BoxDecoration(
                  color: FoodlyColors.blanco,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
            ],
          ),
        ),
        if (initials != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: -48,
            child: Center(
              child: _ProfileAvatar(
                fotoUrl: fotoUrl,
                initials: initials!,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.fotoUrl,
    required this.initials,
  });

  final String? fotoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FoodlyColors.blanco,
        boxShadow: [
          BoxShadow(
            color: FoodlyColors.grisOscuro.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _AvatarContent(fotoUrl: fotoUrl, initials: initials),
    );
  }
}

class _AvatarContent extends StatelessWidget {
  const _AvatarContent({
    required this.fotoUrl,
    required this.initials,
  });

  final String? fotoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final url = fotoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 44,
        backgroundColor: FoodlyColors.grisClaro,
        child: ClipOval(
          child: Image.network(
            url,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _InitialsAvatar(initials: initials),
          ),
        ),
      );
    }

    return _InitialsAvatar(initials: initials);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 44,
      backgroundColor: FoodlyColors.celeste,
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: FoodlyTheme.sansBlack.copyWith(
          fontSize: 30,
          color: FoodlyColors.blanco,
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FoodlyColors.blanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FoodlyColors.grisOscuro.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: FoodlyColors.celeste.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: FoodlyColors.celeste),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: FoodlyTheme.sansBlack.copyWith(
                      fontSize: 16,
                      color: FoodlyColors.grisOscuro,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: FoodlyColors.grisIntermedio),
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: muted
                        ? FoodlyColors.grisIntermedio
                        : FoodlyColors.grisOscuro,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BiometricToggleRow extends StatelessWidget {
  const _BiometricToggleRow({
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: FoodlyColors.celeste.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fingerprint,
              size: 22,
              color: FoodlyColors.celeste,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inicio con biometría',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: FoodlyColors.grisOscuro,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Huella o Face ID en este dispositivo',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: FoodlyColors.grisIntermedio,
                  ),
                ),
              ],
            ),
          ),
          if (loading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: value,
              activeThumbColor: FoodlyColors.celeste,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _ProfileActionRow extends StatelessWidget {
  const _ProfileActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: FoodlyColors.grisIntermedio,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: FoodlyColors.grisIntermedio.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReputacionData {
  const _ReputacionData({
    required this.global,
    required this.detalle,
  });

  final CalificacionGlobalModel global;
  final List<CalificacionDetalleModel> detalle;
}

class _ReputacionSection extends StatefulWidget {
  const _ReputacionSection({super.key, required this.clienteId});

  final int clienteId;

  @override
  State<_ReputacionSection> createState() => _ReputacionSectionState();
}

class _ReputacionSectionState extends State<_ReputacionSection> {
  final _repository = CalificacionRepository();
  late Future<_ReputacionData?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReputacionData?> _load() async {
    final global =
        await _repository.obtenerCalificacionRecibida(widget.clienteId);
    if (global == null) return null;
    final detalle =
        await _repository.obtenerDetalleCalificacionRecibida(widget.clienteId);
    return _ReputacionData(global: global, detalle: detalle);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReputacionData?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const ClientRatingEmptyCard();
        }

        final data = snapshot.data!;
        return ClientRatingSummaryCard(
          global: data.global,
          detalle: data.detalle,
        );
      },
    );
  }
}
