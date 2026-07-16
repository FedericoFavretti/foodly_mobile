import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/api_constants.dart';
import '../core/errors/api_exception.dart';
import '../data/models/direccion_model.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/cliente_profile_repository.dart';
import '../data/repositories/pedido_repository.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/cart/cart_notifier.dart';
import '../domain/cart/cart_storage.dart';
import '../domain/pedido/medio_pago.dart';
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
  MedioPago _medioPago = MedioPago.mercadoPago;

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
              'No pudimos cargar tu dirección guardada. Completá los campos manualmente.',
            ),
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
        medioPago: _medioPago,
      );

      if (_medioPago == MedioPago.mercadoPago) {
        final initPoint = pedido.mpInitPoint?.trim();
        if (initPoint == null || initPoint.isEmpty) {
          throw const ApiException(
            statusCode: 502,
            userMessage:
                'No pudimos generar el link de pago. Intentalo nuevamente.',
          );
        }
        final uri = Uri.tryParse(initPoint);
        // inAppBrowserView (Custom Tabs / SFSafariViewController) mantiene
        // el checkout dentro de la tarea de la app: "salir" vuelve a Foodly
        // en vez de quedar navegando en el historial del navegador externo.
        if (uri == null ||
            !await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
          throw const ApiException(
            statusCode: 0,
            userMessage: 'No pudimos abrir Mercado Pago en tu dispositivo.',
          );
        }
        await CartStorage().savePendingMpPedidoId(pedido.id);
      }

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Código postal (opcional)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Medio de pago',
                    style: FoodlyTheme.sansBlack.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...MedioPago.values.map((medio) {
                    final selected = _medioPago == medio;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: _submitting
                            ? null
                            : () => setState(() => _medioPago = medio),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? FoodlyColors.celeste
                                  : FoodlyColors.grisClaro,
                              width: selected ? 2 : 1,
                            ),
                            color: selected
                                ? FoodlyColors.celeste.withValues(alpha: 0.08)
                                : FoodlyColors.blanco,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: selected
                                    ? FoodlyColors.celeste
                                    : FoodlyColors.grisIntermedio,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      medio.label,
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      medio.descripcion,
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: FoodlyColors.grisIntermedio,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  FoodlyButton(
                    label: _submitting
                        ? (_medioPago == MedioPago.mercadoPago
                              ? 'GENERANDO PAGO...'
                              : 'CONFIRMANDO PEDIDO...')
                        : (_medioPago == MedioPago.mercadoPago
                              ? 'PAGAR CON MERCADO PAGO'
                              : 'CONFIRMAR PEDIDO EN EFECTIVO'),
                    onPressed: _submitting ? null : _confirmarPedido,
                  ),
                ],
              ),
            ),
    );
  }
}
