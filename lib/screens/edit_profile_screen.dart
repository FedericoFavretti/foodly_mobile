import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../core/errors/api_exception.dart';
import '../core/validators/form_validators.dart';
import '../data/models/cliente_profile_model.dart';
import '../data/repositories/cliente_profile_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/foodly_button.dart';
import '../widgets/phone_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  static const routeName = '/editar-perfil';

  final ClienteProfileModel profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileRepository = ClienteProfileRepository();
  final _imagePicker = ImagePicker();

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _calleController;
  late final TextEditingController _numeroController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _codigoPostalController;

  Uint8List? _fotoBytes;
  String? _fotoFilename;
  bool _isLoading = false;

  /// Arranca siempre vacío: el backend no devuelve el celular guardado en
  /// ningún endpoint de perfil hoy, así que no hay forma de precargarlo.
  String _celular = '';

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nombreController = TextEditingController(text: profile.nombre);
    _apellidoController = TextEditingController(text: profile.apellido);
    _calleController = TextEditingController(text: profile.direccion?.calle ?? '');
    _numeroController = TextEditingController(text: profile.direccion?.numero ?? '');
    _ciudadController = TextEditingController(text: profile.direccion?.ciudad ?? '');
    _codigoPostalController = TextEditingController(
      text: profile.direccion?.codigoPostal ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
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
      final updated = await _profileRepository.actualizarPerfil(
        ActualizarPerfilData(
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
      Navigator.pop(context, updated);
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
    final profile = widget.profile;
    ImageProvider? photoProvider;
    if (_fotoBytes != null) {
      photoProvider = MemoryImage(_fotoBytes!);
    } else if (profile.fotoUrl != null && profile.fotoUrl!.trim().isNotEmpty) {
      photoProvider = NetworkImage(profile.fotoUrl!);
    }

    return Scaffold(
      backgroundColor: FoodlyColors.blanco,
      appBar: AppBar(
        backgroundColor: FoodlyColors.celeste,
        foregroundColor: FoodlyColors.blanco,
        title: Text(
          'Editar perfil',
          style: FoodlyTheme.sansBlack.copyWith(fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isLoading ? null : _pickPhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: FoodlyColors.grisClaro,
                          backgroundImage: photoProvider,
                          child: photoProvider == null
                              ? Icon(
                                  Icons.person_outline,
                                  size: 48,
                                  color: FoodlyColors.grisIntermedio,
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: FoodlyColors.celeste,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: FoodlyColors.blanco,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: FoodlyColors.blanco,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JPG o PNG, máx. 5 MB',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: FoodlyColors.grisIntermedio,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SectionLabel('Datos personales'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreController,
              enabled: !_isLoading,
              decoration: const InputDecoration(hintText: 'Nombre'),
              validator: (v) => FormValidators.requiredField(v, 'tu nombre'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apellidoController,
              enabled: !_isLoading,
              decoration: const InputDecoration(hintText: 'Apellido'),
              validator: (v) => FormValidators.requiredField(v, 'tu apellido'),
            ),
            const SizedBox(height: 8),
            Text(
              profile.email,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: FoodlyColors.grisIntermedio,
              ),
            ),
            const SizedBox(height: 16),
            PhoneField(
              enabled: !_isLoading,
              onChanged: (value) => _celular = value,
            ),
            const SizedBox(height: 28),
            _SectionLabel('Dirección de entrega'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _calleController,
              enabled: !_isLoading,
              decoration: const InputDecoration(hintText: 'Calle'),
              validator: (v) => FormValidators.requiredField(v, 'la calle'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numeroController,
              enabled: !_isLoading,
              decoration: const InputDecoration(hintText: 'Número'),
              validator: (v) => FormValidators.requiredField(v, 'el número'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ciudadController,
              enabled: !_isLoading,
              decoration: const InputDecoration(hintText: 'Ciudad'),
              validator: (v) => FormValidators.requiredField(v, 'la ciudad'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codigoPostalController,
              enabled: !_isLoading,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Código postal'),
              validator: (v) =>
                  FormValidators.requiredField(v, 'el código postal'),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              FoodlyButton(
                label: 'GUARDAR CAMBIOS',
                onPressed: _submit,
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: FoodlyTheme.sansBlack.copyWith(
        fontSize: 16,
        color: FoodlyColors.grisOscuro,
      ),
    );
  }
}
