import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/api_constants.dart';
import '../core/errors/api_exception.dart';
import '../data/models/direccion_model.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/cliente_profile_repository.dart';
import '../data/repositories/pedido_repository.dart';
import '../domain/cart/cart_notifier.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/foodly_button.dart';
import 'order_status_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  static const routeName = '/checkout';

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _profileRepository = ClienteProfileRepository();
  final _pedidoRepository = PedidoRepository();
  final _catalogRepository = CatalogRepository();

  final _calleController = TextEditingController();
  final _numeroController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _cpController = TextEditingController();

  bool _loadingProfile = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _calleController.dispose();
    _numeroController.dispose();
    _ciudadController.dispose();
    _cpController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getOrFetch();
      final direccion = profile.direccion;
      if (direccion != null) {
        _calleController.text = direccion.calle;
        _numeroController.text = direccion.numero;
        _ciudadController.text = direccion.ciudad;
        _cpController.text = direccion.codigoPostal ?? '';
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No pudimos cargar tu dirección guardada. Completá los campos manualmente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _confirmarPedido() async {
    final cart = CartNotifier.instance;
    if (cart.isEmpty || cart.localId == null) {
      _showError(PedidoRepository.sinPlatosMessage);
      return;
    }

    if (_catalogRepository.usesMockData || ApiConstants.useMockCatalog) {
      _showError(
        'El pedido contra la API requiere catálogo real del servidor. '
        'Coordiná con backend la implementación de CU-CL04/05.',
      );
      return;
    }

    final calle = _calleController.text.trim();
    final numero = _numeroController.text.trim();
    final ciudad = _ciudadController.text.trim();

    if (calle.isEmpty || numero.isEmpty || ciudad.isEmpty) {
      _showError('Completá el domicilio de entrega.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final profile = await _profileRepository.getOrFetch();
      final pedido = await _pedidoRepository.realizarPedido(
        clienteId: profile.id,
        localId: cart.localId!,
        domicilio: DireccionModel(
          calle: calle,
          numero: numero,
          ciudad: ciudad,
          codigoPostal: _cpController.text.trim(),
        ),
        items: cart.items.toList(),
      );

      cart.clear();
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        OrderStatusScreen.routeName,
        (route) => route.isFirst || route.settings.name == '/app',
        arguments: pedido,
      );
    } on ApiException catch (error) {
      _showError(error.userMessage);
    } on NetworkException catch (error) {
      _showError(error.userMessage);
    } catch (_) {
      _showError('Ocurrió un error al confirmar el pedido.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartNotifier.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Confirmar pedido',
          style: FoodlyTheme.serifTitle.copyWith(fontSize: 22),
        ),
        backgroundColor: FoodlyColors.blanco,
        foregroundColor: FoodlyColors.grisOscuro,
        elevation: 0,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_catalogRepository.usesMockData ||
                      ApiConstants.useMockCatalog)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FoodlyColors.amarillo.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Catálogo en modo demostración: el pedido real necesita '
                        'platos y locales del servidor.',
                        style: GoogleFonts.nunito(fontSize: 13),
                      ),
                    ),
                  Text(
                    cart.localNombre ?? 'Local',
                    style: FoodlyTheme.sansBlack.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${cart.totalItems} plato(s) · Total estimado \$${cart.estimatedTotal.toStringAsFixed(0)}',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: FoodlyColors.grisIntermedio,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Domicilio de entrega',
                    style: FoodlyTheme.sansBlack.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _calleController,
                    decoration: const InputDecoration(labelText: 'Calle'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _numeroController,
                    decoration: const InputDecoration(labelText: 'Número'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ciudadController,
                    decoration: const InputDecoration(labelText: 'Ciudad'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cpController,
                    decoration: const InputDecoration(
                      labelText: 'Código postal (opcional)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Medio de pago: simulado',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: FoodlyColors.grisIntermedio,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FoodlyButton(
                    label: _submitting ? 'CONFIRMANDO...' : 'REALIZAR PEDIDO',
                    onPressed: (_submitting ||
                            _catalogRepository.usesMockData ||
                            ApiConstants.useMockCatalog)
                        ? null
                        : _confirmarPedido,
                  ),
                ],
              ),
            ),
    );
  }
}
