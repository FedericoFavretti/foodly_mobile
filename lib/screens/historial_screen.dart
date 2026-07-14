import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/errors/api_exception.dart';
import '../data/models/mi_calificacion_local_model.dart';
import '../data/models/pedido_response_model.dart';
import '../data/repositories/calificacion_repository.dart';
import '../data/repositories/pedido_repository.dart';
import '../data/repositories/reclamo_repository.dart';
import '../domain/pedido/pedido_list_filter.dart';
import '../domain/pedido/pedido_sort.dart';
import '../domain/reclamo/reclamo_rules.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/calificar_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/foodly_filter_chip.dart';
import '../widgets/pedido_card.dart';
import '../widgets/reclamo_form_dialog.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/wavy_accent.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({
    super.key,
    this.onExploreLocales,
    this.onReclamoCreado,
    this.isTabActive = false,
  });

  static const routeName = '/historial';

  final VoidCallback? onExploreLocales;
  final VoidCallback? onReclamoCreado;
  final bool isTabActive;

  @override
  State<HistorialScreen> createState() => HistorialScreenState();
}

class HistorialScreenState extends State<HistorialScreen>
    with WidgetsBindingObserver {
  final _pedidoRepository = PedidoRepository();
  final _reclamoRepository = ReclamoRepository();
  final _calificacionRepository = CalificacionRepository();
  List<PedidoResponseModel> _pedidos = [];
  /// Calificaciones ya consultadas por local (`null` = sin calificación previa).
  final Map<int, MiCalificacionLocalModel?> _calificacionesPorLocal = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  Object? _error;
  String? _filtroEstado;
  PedidoSortOption _sort = PedidoSortOption.fechaReciente;
  Timer? _pollTimer;

  static const _pollInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPedidos();
  }

  @override
  void didUpdateWidget(covariant HistorialScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTabActive != widget.isTabActive) {
      _syncPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh(silent: true);
    }
  }

  /// Recarga pedidos desde el backend. [silent] evita el skeleton si ya hay datos.
  Future<void> refresh({bool silent = false}) => _loadPedidos(silent: silent);

  Future<void> _loadPedidos({bool silent = false}) async {
    if (!silent || _pedidos.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final pedidos = await _pedidoRepository.listarHistorial(
        estado: _serverEstadoParam,
      );
      if (!mounted) return;
      setState(() {
        _pedidos = pedidos;
        _isLoading = false;
        _isRefreshing = false;
      });
      _prefetchCalificaciones(pedidos);
      _syncPolling();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (!silent || _pedidos.isEmpty) {
          _error = error;
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  void _syncPolling() {
    _pollTimer?.cancel();
    if (!widget.isTabActive) return;
    if (!_pedidos.any((p) => p.esActivo)) return;

    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (mounted && widget.isTabActive) {
        refresh(silent: true);
      }
    });
  }

  Future<void> _reclamar(PedidoResponseModel pedido) async {
    final result = await showReclamoFormDialog(context, pedido: pedido);

    if (result == null || !mounted) return;

    try {
      await _reclamoRepository.realizarReclamo(
        pedidoId: pedido.id,
        motivo: result.motivo,
        tipoCompensacion: result.tipoCompensacion,
        montoReintegro: result.montoReintegro,
      );
      if (!mounted) return;

      setState(() {
        _pedidos = _pedidos
            .map(
              (p) => p.id == pedido.id
                  ? p.copyWith(tieneReclamo: true)
                  : p,
            )
            .toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reclamo registrado correctamente.'),
        ),
      );
      widget.onReclamoCreado?.call();
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

  Future<void> _prefetchCalificaciones(List<PedidoResponseModel> pedidos) async {
    final localIds = pedidos
        .where((p) => _puedeCalificar(p) && p.localId != null)
        .map((p) => p.localId!)
        .toSet();

    for (final localId in localIds) {
      if (_calificacionesPorLocal.containsKey(localId)) continue;
      try {
        final calificacion =
            await _calificacionRepository.obtenerMiCalificacion(localId);
        if (!mounted) return;
        setState(() => _calificacionesPorLocal[localId] = calificacion);
      } catch (_) {
        // Silencioso: el botón sigue disponible y se reintenta al calificar.
      }
    }
  }

  String _labelCalificar(PedidoResponseModel pedido) {
    final localId = pedido.localId;
    if (localId != null && _calificacionesPorLocal[localId] != null) {
      return 'Editar calificación';
    }
    return 'Calificar';
  }

  Future<void> _calificar(PedidoResponseModel pedido) async {
    final localId = pedido.localId;
    if (localId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos identificar el local de este pedido para calificar.',
          ),
        ),
      );
      return;
    }

    MiCalificacionLocalModel? existente = _calificacionesPorLocal[localId];
    if (!_calificacionesPorLocal.containsKey(localId)) {
      try {
        existente =
            await _calificacionRepository.obtenerMiCalificacion(localId);
        if (mounted) {
          setState(() => _calificacionesPorLocal[localId] = existente);
        }
      } on ApiException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.userMessage)),
        );
        return;
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos cargar tu calificación. Intentalo más tarde.'),
          ),
        );
        return;
      }
    }

    final esEdicion = existente != null;

    final result = await showCalificarDialog(
      context: context,
      localNombre: pedido.localNombre,
      puntajeInicial: existente?.puntaje ?? 0,
      comentarioInicial: existente?.comentario ?? '',
      esEdicion: esEdicion,
    );
    } finally {
      comentario.dispose();
    }

    if (result == null || !mounted) return;

    try {
      await _calificacionRepository.calificarLocal(
        localId: localId,
        puntaje: result.puntaje,
        comentario: result.comentario,
      );
      if (!mounted) return;
      final comentarioGuardado = result.comentario.trim();
      setState(() {
        _calificacionesPorLocal[localId] = MiCalificacionLocalModel(
          id: existente?.id ?? 0,
          puntaje: result.puntaje,
          comentario:
              comentarioGuardado.isEmpty ? null : comentarioGuardado,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esEdicion
                ? 'Calificación actualizada correctamente.'
                : '¡Gracias! Tu calificación fue registrada.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos registrar tu calificación. Intentalo más tarde.'),
        ),
      );
    }
  }

  Future<void> _reintentarPago(PedidoResponseModel pedido) async {
    try {
      final pedidoActualizado =
          await _pedidoRepository.reintentarPago(pedido.id);

      if (!mounted) return;

      final initPoint = pedidoActualizado.mpInitPoint?.trim();
      if (initPoint == null || initPoint.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos generar el link de pago. Intentalo más tarde.'),
          ),
        );
        return;
      }

      // Actualizar el pedido en la lista local con los datos frescos.
      setState(() {
        _pedidos = _pedidos.map((p) => p.id == pedido.id ? pedidoActualizado : p).toList();
      });

      final uri = Uri.tryParse(initPoint);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
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

  Future<void> _cancelar(PedidoResponseModel pedido) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Text(
            '¿Cancelar el pedido Nº ${pedido.id} de ${pedido.localNombre}?'),
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

      setState(() {
        _pedidos = _pedidos
            .map(
              (p) => p.id == pedido.id
                  ? p.copyWith(estado: 'Cancelado')
                  : p,
            )
            .toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido cancelado.')),
      );

      // Sincronizar con el servidor en segundo plano.
      await _loadPedidos();
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
    return PedidoListFilter.apply(
      all: all,
      filtroEstado: _filtroEstado,
      sort: _sort,
    );
  }

  /// Estados con filtro server-side; "Activos" y "Todos" traen el historial completo.
  String? get _serverEstadoParam {
    final filtro = _filtroEstado;
    if (filtro == null || filtro == 'Activos') return null;
    return filtro;
  }

  void _applyEstadoFilter(String? estado) {
    if (_filtroEstado == estado) return;
    setState(() => _filtroEstado = estado);
    _loadPedidos();
  }

  void _clearFilters() {
    setState(() {
      _filtroEstado = null;
      _sort = PedidoSortOption.fechaReciente;
    });
    _loadPedidos();
  }

  int get _pedidosActivos => _pedidos.where((p) => p.esActivo).length;

  /// Pedidos confirmados o entregados pueden reclamarse (CU-CL09).
  bool _puedeReclamar(PedidoResponseModel pedido) {
    return ReclamoRules.puedeReclamar(
      estado: pedido.estado,
      tieneReclamo: pedido.tieneReclamo,
    );
  }

  /// Solo pedidos completados o confirmados con local identificado (CU-CL10).
  bool _puedeCalificar(PedidoResponseModel pedido) {
    if (pedido.localId == null) return false;
    final estado = pedido.estado.toLowerCase();
    return estado == 'confirmado' || estado == 'entregado';
  }

  Widget _buildContent() {
    if (_isLoading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      final message = _error is ApiException
          ? (_error as ApiException).userMessage
          : _error is NetworkException
              ? (_error as NetworkException).userMessage
              : 'Ocurrió un error al cargar el historial.';
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
                onPressed: _reload,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final all = _data ?? [];

    if (all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Aún no ha realizado ningún pedido. ¡Explore los locales disponibles y realice su primer pedido!',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: FoodlyColors.grisIntermedio,
            ),
          ),
        ),
      );
    }

    final filtered = _applyFilter(all);

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No se encontraron pedidos que coincidan con los criterios seleccionados.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _filtroEstado = null),
                child: const Text('Limpiar filtro'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final p = filtered[index];
        return _PedidoCard(
          pedido: p,
          onCancel: p.estado.toLowerCase() == 'pendiente'
              ? () => _cancelar(p)
              : null,
          onReclamar: p.estado.toLowerCase() == 'confirmado'
              ? () => _reclamar(p)
              : null,
          onCalificar: () => _calificar(p),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FoodlyColors.blanco,
      body: Column(
        children: [
          _PedidosHero(
            totalPedidos: _pedidos.length,
            pedidosActivos: _pedidosActivos,
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
                  onTap: () => _applyEstadoFilter(null),
                ),
                FoodlyFilterChip(
                  label: 'Activos',
                  selected: _filtroEstado == 'Activos',
                  onTap: () => _applyEstadoFilter('Activos'),
                ),
                FoodlyFilterChip(
                  label: 'Pendiente',
                  selected: _filtroEstado == 'Pendiente',
                  onTap: () => _applyEstadoFilter('Pendiente'),
                ),
                FoodlyFilterChip(
                  label: 'Confirmado',
                  selected: _filtroEstado == 'Confirmado',
                  onTap: () => _applyEstadoFilter('Confirmado'),
                ),
                FoodlyFilterChip(
                  label: 'Entregado',
                  selected: _filtroEstado == 'Entregado',
                  onTap: () => _applyEstadoFilter('Entregado'),
                ),
                FoodlyFilterChip(
                  label: 'Cancelado',
                  selected: _filtroEstado == 'Cancelado',
                  onTap: () => _applyEstadoFilter('Cancelado'),
                ),
                FoodlyFilterChip(
                  label: 'Rechazado',
                  selected: _filtroEstado == 'Rechazado',
                  onTap: () => _applyEstadoFilter('Rechazado'),
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
                  selected: _sort == PedidoSortOption.fechaReciente,
                  onTap: () => setState(
                    () => _sort = PedidoSortOption.fechaReciente,
                  ),
                ),
                FoodlyFilterChip(
                  label: 'Mayor precio',
                  selected: _sort == PedidoSortOption.precioMayor,
                  onTap: () => setState(
                    () => _sort = PedidoSortOption.precioMayor,
                  ),
                ),
                FoodlyFilterChip(
                  label: 'Local A-Z',
                  selected: _sort == PedidoSortOption.localAz,
                  onTap: () => setState(() => _sort = PedidoSortOption.localAz),
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
    if (_isLoading && _pedidos.isEmpty) {
      return const PedidoListSkeleton();
    }

    if (_error != null) {
      final message = _error is ApiException
          ? (_error as ApiException).userMessage
          : _error is NetworkException
              ? (_error as NetworkException).userMessage
              : 'Ocurrió un error al cargar el historial.';
      return ErrorState(message: message, onRetry: _loadPedidos);
    }

    if (_pedidos.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Sin pedidos aún',
        subtitle:
            'Explorá los locales disponibles y realizá tu primer pedido.',
        actionLabel: widget.onExploreLocales != null ? 'Explorar locales' : null,
        onAction: widget.onExploreLocales,
      );
    }

    final filtered = _applyFilter(_pedidos);

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.filter_list_off,
        title: 'Sin resultados',
        subtitle: 'No hay pedidos con el estado seleccionado.',
        actionLabel: 'Limpiar filtros',
        onAction: _clearFilters,
      );
    }

    return RefreshIndicator(
      color: FoodlyColors.celeste,
      onRefresh: () => _loadPedidos(silent: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: filtered.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${filtered.length} ${filtered.length == 1 ? 'pedido' : 'pedidos'}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
            );
          }

          final p = filtered[index - 1];
          return PedidoCard(
            pedido: p,
            onCancel: p.estadoNormalizado == 'Pendiente' ? () => _cancelar(p) : null,
            onReclamar: _puedeReclamar(p) ? () => _reclamar(p) : null,
            reclamoEnviado: p.tieneReclamo,
            onCalificar: _puedeCalificar(p) ? () => _calificar(p) : null,
            calificarLabel: _puedeCalificar(p) ? _labelCalificar(p) : null,
            onReintentarPago: p.permiteReintentarPago ? () => _reintentarPago(p) : null,
          );
        },
      ),
    );
  }
}

class _PedidosHero extends StatelessWidget {
  const _PedidosHero({
    required this.totalPedidos,
    required this.pedidosActivos,
    required this.isRefreshing,
  });

  final int totalPedidos;
  final int pedidosActivos;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final resumen = totalPedidos == 0
        ? 'Todavía no tenés pedidos'
        : pedidosActivos > 0
            ? '$pedidosActivos ${pedidosActivos == 1 ? 'pedido activo' : 'pedidos activos'} · $totalPedidos en total'
            : '$totalPedidos ${totalPedidos == 1 ? 'pedido' : 'pedidos'} en total';

    return ColoredBox(
      color: FoodlyColors.celeste,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis pedidos',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 30,
                          height: 1.05,
                          color: FoodlyColors.blanco,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seguí el estado de tus compras',
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

