import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/errors/api_exception.dart';
import '../data/models/pedido_response_model.dart';
import '../data/repositories/pedido_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  static const routeName = '/historial';

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _pedidoRepository = PedidoRepository();
  late Future<List<PedidoResponseModel>> _historialFuture;
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _historialFuture = _pedidoRepository.listarHistorial();
  }

  void _reload() {
    setState(() => _historialFuture = _pedidoRepository.listarHistorial());
  }

  Future<void> _reclamar(PedidoResponseModel pedido) async {
    final motivo = TextEditingController();
    final compensacion = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Realizar reclamo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pedido Nº ${pedido.id} — ${pedido.localNombre}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: motivo,
                decoration: const InputDecoration(
                  labelText: 'Motivo del reclamo *',
                  hintText: 'Describí el problema...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: compensacion,
                decoration: const InputDecoration(
                  labelText: 'Compensación solicitada',
                  hintText: 'Ej: reembolso, reenvío...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (motivo.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Debe describir el motivo del reclamo antes de enviarlo.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Enviar reclamo'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reclamo registrado como Pendiente. El endpoint de backend se integrará cuando esté disponible.',
        ),
      ),
    );
  }

  Future<void> _calificar(PedidoResponseModel pedido) async {
    int puntaje = 0;
    final comentario = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Calificar local'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pedido.localNombre,
                  style: FoodlyTheme.sansBlack.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return IconButton(
                      onPressed: () => setDialogState(() => puntaje = star),
                      icon: Icon(
                        star <= puntaje ? Icons.star : Icons.star_border,
                        color: FoodlyColors.amarillo,
                        size: 36,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: comentario,
                  decoration: const InputDecoration(
                    labelText: 'Comentario (opcional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (puntaje == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seleccioná un puntaje de 1 a 5.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Calificación de $puntaje estrella(s) registrada. Se integrará con el backend cuando el endpoint esté disponible.',
        ),
      ),
    );
  }

  Future<void> _cancelar(PedidoResponseModel pedido) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text('¿Cancelar el pedido Nº ${pedido.id} de ${pedido.localNombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _pedidoRepository.cancelarPedido(pedido.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido cancelado.')),
      );
      _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    } on NetworkException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
  }

  List<PedidoResponseModel> _applyFilter(List<PedidoResponseModel> all) {
    if (_filtroEstado == null) return all;
    return all
        .where((p) => p.estado.toLowerCase() == _filtroEstado!.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis pedidos',
          style: FoodlyTheme.serifTitle.copyWith(fontSize: 22),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: FoodlyColors.blanco,
        foregroundColor: FoodlyColors.grisOscuro,
        elevation: 0,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _FilterChip(label: 'Todos', active: _filtroEstado == null, onTap: () => setState(() => _filtroEstado = null)),
                _FilterChip(label: 'Pendiente', active: _filtroEstado == 'Pendiente', onTap: () => setState(() => _filtroEstado = 'Pendiente')),
                _FilterChip(label: 'Confirmado', active: _filtroEstado == 'Confirmado', onTap: () => setState(() => _filtroEstado = 'Confirmado')),
                _FilterChip(label: 'Cancelado', active: _filtroEstado == 'Cancelado', onTap: () => setState(() => _filtroEstado = 'Cancelado')),
                _FilterChip(label: 'Rechazado', active: _filtroEstado == 'Rechazado', onTap: () => setState(() => _filtroEstado = 'Rechazado')),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PedidoResponseModel>>(
              future: _historialFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final message = snapshot.error is ApiException
                      ? (snapshot.error as ApiException).userMessage
                      : snapshot.error is NetworkException
                          ? (snapshot.error as NetworkException).userMessage
                          : 'Ocurrió un error al cargar el historial.';
                  return _CenterMessage(
                    message: message,
                    onRetry: _reload,
                  );
                }

                final all = snapshot.data ?? [];

                if (all.isEmpty) {
                  return const _CenterMessage(
                    message:
                        'Aún no ha realizado ningún pedido. ¡Explore los locales disponibles y realice su primer pedido!',
                  );
                }

                final filtered = _applyFilter(all);

                if (filtered.isEmpty) {
                  return const _CenterMessage(
                    message:
                        'No se encontraron pedidos que coincidan con los criterios seleccionados.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    return _PedidoCard(
                      pedido: p,
                      onCancel: p.estado == 'Pendiente'
                          ? () => _cancelar(p)
                          : null,
                      onReclamar: p.estado == 'Confirmado'
                          ? () => _reclamar(p)
                          : null,
                      onCalificar: () => _calificar(p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  const _PedidoCard({
    required this.pedido,
    this.onCancel,
    this.onReclamar,
    this.onCalificar,
  });

  final PedidoResponseModel pedido;
  final VoidCallback? onCancel;
  final VoidCallback? onReclamar;
  final VoidCallback? onCalificar;

  Color _estadoColor() {
    switch (pedido.estado) {
      case 'Pendiente':
        return FoodlyColors.amarillo;
      case 'Confirmado':
        return FoodlyColors.celeste;
      case 'Cancelado':
        return FoodlyColors.grisIntermedio;
      case 'Rechazado':
        return const Color(0xFFD32F2F);
      default:
        return FoodlyColors.grisIntermedio;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pedido.localNombre,
                    style: FoodlyTheme.sansBlack.copyWith(fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _estadoColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pedido.estado,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _estadoColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pedido Nº ${pedido.id}',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: FoodlyColors.grisIntermedio,
              ),
            ),
            const SizedBox(height: 4),
            ...pedido.detalles.map(
              (d) => Text(
                '${d.cantidad}x ${d.platoNombre} — \$${d.subtotal.toStringAsFixed(0)}',
                style: GoogleFonts.nunito(fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: \$${pedido.total.toStringAsFixed(0)}',
              style: FoodlyTheme.sansBold.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                    ),
                    child: const Text('CANCELAR'),
                  ),
                if (onReclamar != null)
                  TextButton(
                    onPressed: onReclamar,
                    style: TextButton.styleFrom(
                      foregroundColor: FoodlyColors.grisOscuro,
                    ),
                    child: const Text('RECLAMAR'),
                  ),
                if (onCalificar != null)
                  TextButton.icon(
                    onPressed: onCalificar,
                    icon: const Icon(Icons.star_border, size: 18),
                    label: const Text('CALIFICAR'),
                    style: TextButton.styleFrom(
                      foregroundColor: FoodlyColors.celeste,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
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
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
