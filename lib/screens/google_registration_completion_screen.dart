import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../core/auth/biometric_service.dart';
import '../core/auth/post_login_helper.dart';
import '../core/errors/api_exception.dart';
import '../core/validators/form_validators.dart';
import '../data/models/direccion_model.dart';
import '../data/repositories/auth_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/foodly_button.dart';
import 'main_screen.dart';

class GoogleRegistrationCompletionScreen extends StatefulWidget {
  const GoogleRegistrationCompletionScreen({
    super.key,
    required this.pendiente,
  });

  static const routeName = '/register/google/completar';

  final GoogleRegistroPendienteResponse pendiente;

  @override
  State<GoogleRegistrationCompletionScreen> createState() =>
      _GoogleRegistrationCompletionScreenState();
}

class _GoogleRegistrationCompletionScreenState
    extends State<GoogleRegistrationCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentoController = TextEditingController();
  final _calleController = TextEditingController();
  final _numeroController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _codigoPostalController = TextEditingController();
  final _authRepository = AuthRepository();
  final _biometricService = LocalAuthBiometricService();
  final _imagePicker = ImagePicker();

  Uint8List? _fotoBytes;
  String? _fotoFilename;
  bool _isLoading = false;

  GoogleRegistroPendienteResponse get _pendiente => widget.pendiente;

  @override
  void dispose() {
    _documentoController.dispose();
    _calleController.dispose();
    _numeroController.dispose();
    _ciudadController.dispose();
    _codigoPostalController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setState(() {
      _fotoBytes = bytes;
      _fotoFilename = image.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authRepository.completarRegistroGoogle(
        tokenRegistro: _pendiente.tokenRegistro,
        documento: _documentoController.text.trim(),
        direccion: DireccionModel(
          calle: _calleController.text.trim(),
          numero: _numeroController.text.trim(),
          ciudad: _ciudadController.text.trim(),
          codigoPostal: _codigoPostalController.text.trim().isEmpty
              ? null
              : _codigoPostalController.text.trim(),
        ),
        aceptaTerminos: true,
        fotoBytes: _fotoBytes != null ? List<int>.from(_fotoBytes!) : null,
        fotoFilename: _fotoFilename,
      );

      if (!mounted) return;
      await offerBiometricIfNeeded(context, _biometricService);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, MainScreen.routeName);
    } on ApiException catch (error) {
      _showMessage(error.userMessage);
    } on NetworkException catch (error) {
      _showMessage(error.userMessage);
    } catch (_) {
      _showMessage('No se pudo completar el registro. Intentalo más tarde.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      onLogoTap: () => Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (_) => false,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Completá tu registro',
              textAlign: TextAlign.center,
              style: FoodlyTheme.serifTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Solo faltan unos datos más para terminar.',
              textAlign: TextAlign.center,
              style: FoodlyTheme.serifSection.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 20),

            // ── Info de Google (read-only) ────────────────────────────────
            _GoogleInfoCard(pendiente: _pendiente),
            const SizedBox(height: 24),

            // ── Documento ─────────────────────────────────────────────────
            TextFormField(
              controller: _documentoController,
              keyboardType: TextInputType.number,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: 'Documento de identidad (CI)',
              ),
              validator: FormValidators.cedula,
            ),
            const SizedBox(height: 12),

            // ── Dirección ─────────────────────────────────────────────────
            _SectionLabel(label: 'Dirección'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _calleController,
              enabled: !_isLoading,
              decoration: const InputDecoration(hintText: 'Calle'),
              validator: (v) => FormValidators.requiredField(v, 'la calle'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _numeroController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(hintText: 'Número'),
                    validator: (v) =>
                        FormValidators.requiredField(v, 'el número'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _ciudadController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(hintText: 'Ciudad'),
                    validator: (v) =>
                        FormValidators.requiredField(v, 'la ciudad'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codigoPostalController,
              keyboardType: TextInputType.number,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: 'Código postal (opcional)',
              ),
            ),
            const SizedBox(height: 16),

            // ── Foto ──────────────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickPhoto,
              icon: _fotoBytes != null
                  ? const Icon(Icons.check_circle_outline,
                      color: Color(0xFF2E7D32))
                  : const Icon(Icons.photo_outlined),
              label: Text(
                _fotoFilename ?? 'Foto de perfil (opcional)',
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _fotoBytes != null
                    ? const Color(0xFF2E7D32)
                    : FoodlyColors.grisOscuro,
                side: BorderSide(
                  color: _fotoBytes != null
                      ? const Color(0xFF2E7D32)
                      : FoodlyColors.grisIntermedio,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 28),

            // ── Botón principal ───────────────────────────────────────────
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              FoodlyButton(
                label: 'FINALIZAR REGISTRO',
                onPressed: _submit,
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (_) => false,
                      ),
              child: Text(
                'Cancelar y volver al inicio de sesión',
                style: FoodlyTheme.sansBold.copyWith(
                  color: FoodlyColors.grisIntermedio,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con la info que vino de Google (solo lectura).
class _GoogleInfoCard extends StatelessWidget {
  const _GoogleInfoCard({required this.pendiente});

  final GoogleRegistroPendienteResponse pendiente;

  @override
  Widget build(BuildContext context) {
    final nombre = [pendiente.nombre, pendiente.apellido]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FoodlyColors.celeste.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FoodlyColors.celeste.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Avatar circular
          _GoogleAvatar(url: pendiente.foto, nombre: nombre),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (nombre.isNotEmpty)
                  Text(
                    nombre,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: FoodlyColors.grisOscuro,
                    ),
                  ),
                Text(
                  pendiente.email,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: FoodlyColors.grisIntermedio,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: FoodlyColors.celeste.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Cuenta Google verificada',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: FoodlyColors.celeste,
                    ),
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

class _GoogleAvatar extends StatelessWidget {
  const _GoogleAvatar({this.url, required this.nombre});

  final String? url;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'G';

    return CircleAvatar(
      radius: 26,
      backgroundColor: FoodlyColors.celeste.withValues(alpha: 0.2),
      backgroundImage: (url != null && url!.isNotEmpty)
          ? NetworkImage(url!)
          : null,
      child: (url == null || url!.isEmpty)
          ? Text(
              initial,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: FoodlyColors.celeste,
              ),
            )
          : null,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: FoodlyColors.grisIntermedio,
        letterSpacing: 0.5,
      ),
    );
  }
}
