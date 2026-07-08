import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/errors/api_exception.dart';
import '../data/models/pedido_response_model.dart';
import '../data/models/reclamo_listado_model.dart';
import '../data/repositories/pedido_repository.dart';
import '../data/repositories/reclamo_repository.dart';
import '../domain/reclamo/reclamo_rules.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/foodly_filter_chip.dart';
import '../widgets/reclamo_card.dart';
import '../widgets/reclamo_form_dialog.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/wavy_accent.dart';

enum _ReclamoSortOption { fechaReciente, localAz, pendientesPrimero }

class ReclamosScreen extends StatefulWidget {
  const ReclamosScreen({super.key, this.onExploreLocales});

  static const routeName = '/reclamos';

  final VoidCallback? onExploreLocales;

  @override
  State<ReclamosScreen> createState() => ReclamosScreenState();
}

class ReclamosScreenState extends State<ReclamosScreen>
    with WidgetsBindingObserver {
  final _reclamoRepository = ReclamoRepository();
  final _pedidoRepository = PedidoRepository();
  List<ReclamoListadoModel> _reclamos = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isCreatingReclamo = false;
  Object? _error;
  String? _filtroEstado;
  _ReclamoSortOption _sort = _ReclamoSortOption.fechaReciente;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReclamos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh(silent: true);
    }
  }

  Future<void> refresh({bool silent = false}) => _loadReclamos(silent: silent);

  Future<void> _loadReclamos({bool silent = false}) async {
    if (!silent || _reclamos.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final reclamos = await _reclamoRepository.listarMisReclamos();
      if (!mounted) return;
      setState(() {
        _reclamos = reclamos;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (!silent || _reclamos.isEmpty) {
          _error = error;
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _nuevoReclamo() async {
    setState(() => _isCreatingReclamo = true);
    try {
      final pedidos = await _pedidoRepository.listarHistorial();
      final elegibles = pedidos
          .where(
            (p) => ReclamoRules.puedeReclamar(
              estado: p.estadoNormalizado,
              tieneReclamo: p.tieneReclamo,
            ),
          )
          .toList();

      if (!mounted) return;

      if (elegibles.isEmpty) {
        _showMessage(
          'No tenés pedidos confirmados o entregados sin reclamo.',
        );
        return;
      }

      final pedido = await showModalBottomSheet<PedidoResponseModel>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Elegí un pedido',
                  style: FoodlyTheme.serifSection.copyWith(fontSize: 20),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: elegibles.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = elegibles[index];
                    return ListTile(
                      title: Text('Pedido Nº ${p.id} — ${p.localNombre}'),
                      subtitle: Text(
                        '${p.estadoNormalizado} · \$${p.total.toStringAsFixed(0)}',
                      ),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      if (pedido == null || !mounted) return;

      final form = await showReclamoFormDialog(context, pedido: pedido);
      if (form == null || !mounted) return;

      await _reclamoRepository.realizarReclamo(
        pedidoId: pedido.id,
        motivo: form.motivo,
        tipoCompensacion: form.tipoCompensacion,
        montoReintegro: form.montoReintegro,
      );

      if (!mounted) return;
      _showMessage('Reclamo registrado correctamente.');
      await _loadReclamos(silent: true);
    } on ApiException catch (error) {
      _showMessage(error.userMessage);
    } on NetworkException catch (error) {
      _showMessage(error.userMessage);
    } catch (_) {
      _showMessage('No pudimos registrar el reclamo.');
    } finally {
      if (mounted) setState(() => _isCreatingReclamo = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<ReclamoListadoModel> _applyFilter(List<ReclamoListadoModel> source) {
    var filtered = source;

    if (_filtroEstado == 'Pendiente') {
      filtered = filtered.where((r) => r.esPendiente).toList();
    } else if (_filtroEstado == 'Atendido') {
      filtered = filtered.where((r) => r.esAtendido).toList();
    }

    filtered = List<ReclamoListadoModel>.from(filtered);

    switch (_sort) {
      case _ReclamoSortOption.fechaReciente:
        filtered.sort((a, b) {
          final fa = a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
          final fb = b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
          return fb.compareTo(fa);
        });
      case _ReclamoSortOption.localAz:
        filtered.sort(
          (a, b) => a.localNombre.toLowerCase().compareTo(
                b.localNombre.toLowerCase(),
              ),
        );
      case _ReclamoSortOption.pendientesPrimero:
        filtered.sort((a, b) {
          if (a.esPendiente != b.esPendiente) {
            return a.esPendiente ? -1 : 1;
          }
          final fa = a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
          final fb = b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
          return fb.compareTo(fa);
        });
    }

    return filtered;
  }

  int get _reclamosPendientes => _reclamos.where((r) => r.esPendiente).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FoodlyColors.blanco,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreatingReclamo ? null : _nuevoReclamo,
        backgroundColor: FoodlyColors.celeste,
        foregroundColor: FoodlyColors.blanco,
        icon: _isCreatingReclamo
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: FoodlyColors.blanco,
                ),
              )
            : const Icon(Icons.add),
        label: const Text('Nuevo reclamo'),
      ),
      body: Column(
        children: [
          _ReclamosHero(
            totalReclamos: _reclamos.length,
            reclamosPendientes: _reclamosPendientes,
            isRefreshing: _isRefreshing,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                FoodlyFilterChip(
                  label: 'Todos',
                  selected: _filtroEstado == null,
                  onTap: () => setState(() => _filtroEstado = null),
                ),
                FoodlyFilterChip(
                  label: 'Pendiente',
                  selected: _filtroEstado == 'Pendiente',
                  onTap: () => setState(() => _filtroEstado = 'Pendiente'),
                ),
                FoodlyFilterChip(
                  label: 'Atendido',
                  selected: _filtroEstado == 'Atendido',
                  onTap: () => setState(() => _filtroEstado = 'Atendido'),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                FoodlyFilterChip(
                  label: 'Recientes',
                  selected: _sort == _ReclamoSortOption.fechaReciente,
                  onTap: () => setState(
                    () => _sort = _ReclamoSortOption.fechaReciente,
                  ),
                ),
                FoodlyFilterChip(
                  label: 'Pendientes primero',
                  selected: _sort == _ReclamoSortOption.pendientesPrimero,
                  onTap: () => setState(
                    () => _sort = _ReclamoSortOption.pendientesPrimero,
                  ),
                ),
                FoodlyFilterChip(
                  label: 'Local A-Z',
                  selected: _sort == _ReclamoSortOption.localAz,
                  onTap: () =>
                      setState(() => _sort = _ReclamoSortOption.localAz),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _reclamos.isEmpty) {
      return const PedidoListSkeleton();
    }

    if (_error != null) {
      final message = _error is ApiException
          ? (_error as ApiException).userMessage
          : _error is NetworkException
              ? (_error as NetworkException).userMessage
              : 'Ocurrió un error al cargar tus reclamos.';
      return ErrorState(message: message, onRetry: _loadReclamos);
    }

    if (_reclamos.isEmpty) {
      return EmptyState(
        icon: Icons.support_agent_outlined,
        title: 'Sin reclamos',
        subtitle:
            'Cuando realices un reclamo sobre un pedido, lo verás acá con su estado y la respuesta del local.',
        actionLabel: 'Crear reclamo',
        onAction: _isCreatingReclamo ? null : _nuevoReclamo,
      );
    }

    final filtered = _applyFilter(_reclamos);

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list_off,
        title: 'Sin resultados',
        subtitle: 'No hay reclamos con el filtro seleccionado.',
        actionLabel: 'Limpiar filtros',
        onAction: () => setState(() {
          _filtroEstado = null;
          _sort = _ReclamoSortOption.fechaReciente;
        }),
      );
    }

    return RefreshIndicator(
      color: FoodlyColors.celeste,
      onRefresh: () => _loadReclamos(silent: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
        itemCount: filtered.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${filtered.length} ${filtered.length == 1 ? 'reclamo' : 'reclamos'}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
            );
          }

          return ReclamoCard(reclamo: filtered[index - 1]);
        },
      ),
    );
  }
}

class _ReclamosHero extends StatelessWidget {
  const _ReclamosHero({
    required this.totalReclamos,
    required this.reclamosPendientes,
    required this.isRefreshing,
  });

  final int totalReclamos;
  final int reclamosPendientes;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final resumen = totalReclamos == 0
        ? 'Todavía no tenés reclamos'
        : reclamosPendientes > 0
            ? '$reclamosPendientes en revisión · $totalReclamos en total'
            : '$totalReclamos ${totalReclamos == 1 ? 'reclamo' : 'reclamos'}';

    return ColoredBox(
      color: FoodlyColors.celeste,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis reclamos',
                        style: FoodlyTheme.sansBlack.copyWith(
                          fontSize: 30,
                          height: 1.05,
                          color: FoodlyColors.blanco,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seguí la respuesta del local',
                        style: FoodlyTheme.sansBold.copyWith(
                          fontSize: 15,
                          color: FoodlyColors.amarillo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resumen,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: FoodlyColors.blanco.withValues(alpha: 0.92),
                        ),
                      ),
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
    );
  }
}
