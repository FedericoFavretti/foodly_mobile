import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/catalog/catalog_filter.dart';
import '../core/errors/api_exception.dart';
import '../data/models/local_model.dart';
import '../data/models/mi_calificacion_local_model.dart';
import '../data/models/plato_model.dart';
import '../data/repositories/calificacion_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../domain/cart/cart_notifier.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/calificar_dialog.dart';
import '../widgets/cart_fab.dart';
import '../widgets/empty_state.dart';
import '../widgets/foodly_filter_chip.dart';
import '../widgets/local_rating_card.dart';
import '../widgets/plato_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/wavy_accent.dart';

class LocalDetailScreen extends StatefulWidget {
  const LocalDetailScreen({super.key, required this.localId});

  static const routeName = '/local';

  final int localId;

  @override
  State<LocalDetailScreen> createState() => _LocalDetailScreenState();
}

class _LocalDetailScreenState extends State<LocalDetailScreen> {
  final _repository = CatalogRepository();
  final _calificacionRepository = CalificacionRepository();
  final _searchController = TextEditingController();

  late Future<_LocalDetailData> _dataFuture;
  String _query = '';
  PlatoSortOption _sort = PlatoSortOption.nombre;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reloadData() async {
    setState(() => _dataFuture = _loadData());
    await _dataFuture;
  }

  Future<void> _agregarPlato(
    BuildContext context,
    _LocalDetailData data,
    PlatoModel plato,
  ) async {
    try {
      CartNotifier.instance.addPlato(plato: plato, local: data.local);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plato.nombre} agregado al carrito'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on CartConflictException catch (error) {
      if (!context.mounted) return;
      final reemplazar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cambiar local'),
          content: Text(error.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vaciar y continuar'),
            ),
          ],
        ),
      );
      if (reemplazar == true) {
        CartNotifier.instance.replaceLocalAndAdd(
          plato: plato,
          local: data.local,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${plato.nombre} agregado al carrito'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<_LocalDetailData> _loadData() async {
    final local = await _repository.obtenerLocal(widget.localId);
    if (local == null) {
      throw const ApiException(
        statusCode: 404,
        userMessage: 'El local solicitado no existe.',
      );
    }

    MiCalificacionLocalModel? miCalificacion;
    try {
      miCalificacion =
          await _calificacionRepository.obtenerMiCalificacion(widget.localId);
    } catch (_) {
      // Silencioso: la card sigue permitiendo calificar.
    }

    final platos = await _repository.platosDeLocal(widget.localId);
    return _LocalDetailData(
      local: local,
      platos: platos,
      miCalificacion: miCalificacion,
    );
  }

  Future<void> _calificarLocal(_LocalDetailData data) async {
    final existente = data.miCalificacion;
    final esEdicion = existente != null;

    final result = await showCalificarDialog(
      context: context,
      localNombre: data.local.nombre,
      puntajeInicial: existente?.puntaje ?? 0,
      comentarioInicial: existente?.comentario ?? '',
      esEdicion: esEdicion,
    );

    if (result == null || !mounted) return;

    try {
      await _calificacionRepository.calificarLocal(
        localId: widget.localId,
        puntaje: result.puntaje,
        comentario: result.comentario,
      );
      if (!mounted) return;

      final comentarioGuardado = result.comentario.trim();
      final actualizada = MiCalificacionLocalModel(
        id: existente?.id ?? 0,
        puntaje: result.puntaje,
        comentario: comentarioGuardado.isEmpty ? null : comentarioGuardado,
      );

      setState(() {
        _dataFuture = Future.value(
          _LocalDetailData(
            local: data.local,
            platos: data.platos,
            miCalificacion: actualizada,
          ),
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
          content: Text(
            'No pudimos registrar tu calificación. Intentalo más tarde.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FoodlyColors.blanco,
      floatingActionButton: const CartFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: FutureBuilder<_LocalDetailData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _LocalMenuHeroSkeleton(onBack: () => Navigator.pop(context)),
                ),
                const SliverToBoxAdapter(child: PlatoListSkeleton(count: 3)),
              ],
            );
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).userMessage
                : snapshot.error is NetworkException
                    ? (snapshot.error as NetworkException).userMessage
                    : 'Ocurrió un error al cargar el local.';
            return _ErrorScaffold(
              message: message,
              onBack: () => Navigator.pop(context),
              onRetry: _reloadData,
            );
          }

          final data = snapshot.data!;
          final platos = CatalogFilter.filterPlatos(
            platos: data.platos,
            localId: widget.localId,
            query: _query,
            sort: _sort,
          );

          return RefreshIndicator(
            color: FoodlyColors.celeste,
            onRefresh: _reloadData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _LocalMenuHero(
                    local: data.local,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: LocalRatingCard(
                    miCalificacion: data.miCalificacion,
                    onCalificar: () => _calificarLocal(data),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar plato...',
                        hintStyle: GoogleFonts.nunito(
                          color: FoodlyColors.grisIntermedio,
                        ),
                        filled: true,
                        fillColor: FoodlyColors.grisClaro,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: FoodlyColors.celeste,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(
                            color: FoodlyColors.celeste,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Row(
                      children: [
                        FoodlyFilterChip(
                          label: 'Nombre',
                          selected: _sort == PlatoSortOption.nombre,
                          onTap: () =>
                              setState(() => _sort = PlatoSortOption.nombre),
                        ),
                        FoodlyFilterChip(
                          label: 'Precio',
                          selected: _sort == PlatoSortOption.precio,
                          onTap: () =>
                              setState(() => _sort = PlatoSortOption.precio),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!data.local.estaAbierto)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _ClosedBanner(),
                    ),
                  ),
                if (platos.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.restaurant_menu,
                      title: 'Sin platos',
                      subtitle: _query.trim().isEmpty
                          ? 'Este local aún no tiene platos publicados.'
                          : 'No se encontraron platos con esa búsqueda.',
                      actionLabel: _query.trim().isNotEmpty ? 'Limpiar búsqueda' : null,
                      onAction: _query.trim().isNotEmpty
                          ? () => _searchController.clear()
                          : null,
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'Menú',
                            style: FoodlyTheme.serifSection.copyWith(fontSize: 22),
                          ),
                          const Spacer(),
                          Text(
                            '${platos.length} ${platos.length == 1 ? 'plato' : 'platos'}',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: FoodlyColors.grisIntermedio,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final plato = platos[index];
                          return PlatoCard(
                            plato: plato,
                            canAdd: data.local.estaAbierto,
                            onAdd: () => _agregarPlato(context, data, plato),
                          );
                        },
                        childCount: platos.length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LocalMenuHero extends StatelessWidget {
  const _LocalMenuHero({
    required this.local,
    required this.onBack,
  });

  final LocalModel local;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 240 + topInset,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _HeroImage(url: local.imagenPrincipal),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      FoodlyColors.grisOscuro.withValues(alpha: 0.35),
                      FoodlyColors.grisOscuro.withValues(alpha: 0.15),
                      FoodlyColors.grisOscuro.withValues(alpha: 0.82),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
              Positioned(
                top: topInset + 8,
                left: 8,
                child: _BackButton(onPressed: onBack),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _HeroBadge(
                          label: local.estaAbierto ? 'Abierto' : 'Cerrado',
                          background: local.estaAbierto
                              ? FoodlyColors.blanco.withValues(alpha: 0.95)
                              : FoodlyColors.grisOscuro.withValues(alpha: 0.85),
                          foreground: local.estaAbierto
                              ? FoodlyColors.celeste
                              : FoodlyColors.blanco,
                        ),
                        const SizedBox(width: 8),
                        _HeroBadge(
                          label: '★ ${local.calificacionGlobal.toStringAsFixed(1)}',
                          background:
                              FoodlyColors.grisOscuro.withValues(alpha: 0.72),
                          foreground: FoodlyColors.amarillo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      local.nombre,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 30,
                        height: 1.05,
                        color: FoodlyColors.blanco,
                      ),
                    ),
                    if (local.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        local.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          height: 1.35,
                          color: FoodlyColors.blanco.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                    if (local.direccion?.ciudad.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: FoodlyColors.amarillo.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              local.direccion!.ciudad,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: FoodlyColors.amarillo,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        ColoredBox(
          color: FoodlyColors.celeste,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 8, top: 4),
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
      ],
    );
  }
}

class _LocalMenuHeroSkeleton extends StatelessWidget {
  const _LocalMenuHeroSkeleton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: FoodlyColors.grisClaro,
          child: SizedBox(
            height: 240 + topInset,
            child: Stack(
              children: [
                Positioned(
                  top: topInset + 8,
                  left: 8,
                  child: _BackButton(onPressed: onBack),
                ),
              ],
            ),
          ),
        ),
        Container(
          height: 22,
          color: FoodlyColors.blanco,
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [FoodlyColors.celeste, FoodlyColors.celesteOscuro],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.storefront_outlined,
            size: 72,
            color: FoodlyColors.blanco,
          ),
        ),
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [FoodlyColors.celeste, FoodlyColors.celesteOscuro],
          ),
        ),
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: FoodlyColors.blanco),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FoodlyColors.blanco.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back, color: FoodlyColors.grisOscuro),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _ClosedBanner extends StatelessWidget {
  const _ClosedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FoodlyColors.amarillo.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FoodlyColors.amarillo.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: FoodlyColors.grisOscuro, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este local está cerrado y no acepta pedidos por el momento.',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: FoodlyColors.grisOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Menú'),
      ),
      body: Center(
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
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: FoodlyColors.celeste,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalDetailData {
  const _LocalDetailData({
    required this.local,
    required this.platos,
    this.miCalificacion,
  });

  final LocalModel local;
  final List<PlatoModel> platos;
  final MiCalificacionLocalModel? miCalificacion;
}
