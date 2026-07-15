import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../core/auth/google_sign_in_service.dart';
import '../core/errors/api_exception.dart';
import '../core/validators/form_validators.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/cliente_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/foodly_button.dart';
import '../widgets/google_icon.dart';
import '../widgets/password_field.dart';
import '../widgets/phone_field.dart';
import 'activate_account_screen.dart';
import 'google_registration_completion_screen.dart';
import '../widgets/wavy_accent.dart';

const _passwordHint = [
  'Un largo mínimo de 8 caracteres',
  'Al menos 1 letra mayúscula',
  'Al menos 1 número',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.googleSignInService,
  });

  static const routeName = '/register';

  final GoogleSignInService? googleSignInService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _calleController = TextEditingController();
  final _numeroController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _codigoPostalController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _clienteRepository = ClienteRepository();
  final _authRepository = AuthRepository();
  late final GoogleSignInService _googleSignInService =
      widget.googleSignInService ?? PlatformGoogleSignInService();
  final _imagePicker = ImagePicker();

  String _celular = '';
  Uint8List? _fotoBytes;
  String? _fotoFilename;
  bool _isLoading = false;

  bool get _googleConfigured => _googleSignInService.isConfigured;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _documentoController.dispose();
    _calleController.dispose();
    _numeroController.dispose();
    _ciudadController.dispose();
    _codigoPostalController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _registerWithGoogle() async {
    if (!_googleConfigured) {
      _showMessage(
        'Google Sign-In no está configurado. Definí GOOGLE_SERVER_CLIENT_ID al compilar.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Paso 1: obtener token de Google
      final tokens = await _googleSignInService.signIn();
      if (tokens == null) return;

      // Paso 2: iniciar registro — verifica email y devuelve tokenRegistro + datos de Google
      final pendiente = await _authRepository.iniciarRegistroGoogle(
        idToken: tokens.accessToken,
      );

      if (!mounted) return;
      // Paso 3: navegar a la pantalla de completar registro con los datos de Google
      Navigator.pushReplacementNamed(
        context,
        GoogleRegistrationCompletionScreen.routeName,
        arguments: pendiente,
      );
    } on ApiException catch (error) {
      _showMessage(error.userMessage);
    } on NetworkException catch (error) {
      _showMessage(error.userMessage);
    } catch (_) {
      _showMessage('No se pudo iniciar el registro con Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _clienteRepository.registrar(
        RegistroClienteData(
          email: _emailController.text,
          password: _passwordController.text,
          documento: _documentoController.text,
          nombre: _nombreController.text,
          apellido: _apellidoController.text,
          calle: _calleController.text,
          numero: _numeroController.text,
          ciudad: _ciudadController.text,
          codigoPostal: _codigoPostalController.text,
          celular: _celular,
          fotoBytes: _fotoBytes,
          fotoFilename: _fotoFilename,
        ),
      );
      if (!mounted) return;
      final email = _emailController.text.trim();
      final goActivate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cuenta creada'),
          content: const Text(
            'Te enviamos un correo de activación. Revisá tu bandeja y hacé clic en el enlace para activar tu cuenta antes de iniciar sesión.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ENTENDIDO'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ACTIVAR AHORA'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (goActivate == true) {
        Navigator.pushReplacementNamed(
          context,
          ActivateAccountScreen.routeName,
          arguments: email,
        );
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on ApiException catch (error) {
      _showMessage(error.userMessage);
    } on NetworkException catch (error) {
      _showMessage(error.userMessage);
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
                'Registrate en Foodly',
                textAlign: TextAlign.center,
                style: FoodlyTheme.serifTitle,
              ),
              const SizedBox(height: 20),
              FoodlyButton(
                label: 'CONTINUAR CON GOOGLE',
                variant: FoodlyButtonVariant.outline,
                leading: const GoogleIcon(),
                onPressed:
                    _isLoading || !_googleConfigured ? null : _registerWithGoogle,
              ),
              if (!_googleConfigured) ...[
                const SizedBox(height: 8),
                Text(
                  'Requiere GOOGLE_SERVER_CLIENT_ID (--dart-define)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: FoodlyColors.grisIntermedio,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Vas a completar tus datos en el siguiente paso',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: SizedBox(height: 12, child: WavyAccent())),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('o'),
                  ),
                  Expanded(child: SizedBox(height: 12, child: WavyAccent())),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Ingresa tus datos para registrarte',
                textAlign: TextAlign.center,
                style: FoodlyTheme.serifSection,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                enabled: !_isLoading,
                decoration: const InputDecoration(hintText: 'Nombre'),
                validator: (v) => FormValidators.requiredField(v, 'tu nombre'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _apellidoController,
                enabled: !_isLoading,
                decoration: const InputDecoration(hintText: 'Apellido'),
                validator: (v) => FormValidators.requiredField(v, 'tu apellido'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _documentoController,
                keyboardType: TextInputType.number,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  hintText: 'Documento de identidad',
                ),
                validator: FormValidators.cedula,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _calleController,
                enabled: !_isLoading,
                decoration: const InputDecoration(hintText: 'Calle'),
                validator: (v) => FormValidators.requiredField(v, 'la calle'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(hintText: 'Número'),
                validator: (v) => FormValidators.requiredField(v, 'el número'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ciudadController,
                enabled: !_isLoading,
                decoration: const InputDecoration(hintText: 'Ciudad'),
                validator: (v) => FormValidators.requiredField(v, 'la ciudad'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codigoPostalController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_isLoading,
                decoration: const InputDecoration(hintText: 'Código postal (opcional)'),
              ),
              const SizedBox(height: 12),
              PhoneField(
                enabled: !_isLoading,
                onChanged: (value) => _celular = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  hintText: 'Correo electrónico',
                ),
                validator: FormValidators.email,
              ),
              const SizedBox(height: 12),
              PasswordField(
                label: 'Contraseña',
                hint: _passwordHint,
                controller: _passwordController,
              ),
              const SizedBox(height: 12),
              PasswordField(
                label: 'Confirmar contraseña',
                controller: _confirmPasswordController,
                validator: (value) => FormValidators.confirmPassword(
                  _passwordController.text,
                  value,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickPhoto,
                icon: const Icon(Icons.photo_outlined),
                label: Text(
                  _fotoFilename ?? 'Foto de perfil (opcional)',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                FoodlyButton(
                  label: 'REGISTRARSE',
                  onPressed: _submit,
                ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  text: '¿Ya tenés cuenta? ',
                  style: GoogleFonts.nunito(
                    color: FoodlyColors.grisIntermedio,
                    fontSize: 15,
                  ),
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                ),
                        child: Text(
                          'Iniciá sesión',
                          style: FoodlyTheme.sansBold.copyWith(
                            color: FoodlyColors.celeste,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
    );
  }
}
