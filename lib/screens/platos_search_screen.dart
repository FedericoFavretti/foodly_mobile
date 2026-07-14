import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/catalog/catalog_filter.dart';
import '../core/constants/api_constants.dart';
import '../core/errors/api_exception.dart';
import '../data/repositories/catalog_repository.dart';
import '../domain/catalog/busqueda_platos_filter.dart';
import '../domain/catalog/plato_busqueda_item.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/foodly_filter_chip.dart';
import '../widgets/plato_busqueda_card.dart';
import '../widgets/skeleton_loader.dart';
import 'local_detail_screen.dart';

class PlatosSearchScreen extends StatefulWidget {
  const PlatosSearchScreen({super.key});

  static const routeName = '/platos-busqueda';

  @override
  State<PlatosSearchScreen> createState() => _PlatosSearchScreenState();
}

class _PlatosSearchScreenState extends State<PlatosSearchScreen> {
  final _catalogRepository = CatalogRepository();
  final _searchController = TextEditingController();

  String _query = '';
  bool _soloPromociones = false;
  PlatoSearchSort _sort = PlatoSearchSort.none;
  int? _categoriaId;
  Timer? _searchDebounce;
  Future<List<PlatoBusquedaItem>>? _resultsFuture;

  BusquedaPlatosFilter get _activeFilter => BusquedaPlatosFilter(
        query: _query,
        soloPromociones: _soloPromociones,
        sort: _sort,
      );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _reloadResults();
  }

  void _onSearchChanged() {
    final nextQuery = _searchController.text;
    if (nextQuery == _query) return;
    setState(() => _query = nextQuery);

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _reloadResults);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _reloadResults() {
    final filter = _activeFilter;
    setState(() {
      _resultsFuture = _catalogRepository.buscarPlatos(filter);
    });
  }

  void _setSoloPromociones(bool value) {
    setState(() => _soloPromociones = value);
    _reloadResults();
  }

  void _applySort(PlatoSearchSort sort) {
    setState(() => _sort = sort);
    _reloadResults();
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    setState(() {
      _searchController.clear();
      _query = '';
      _soloPromociones = false;
      _sort = PlatoSearchSort.none;
      _categoriaId = null;
    });
    _reloadResults();
  }

  void _setCategoriaId(int? categoriaId) {
    setState(() => _categoriaId = categoriaId);
  }

  void _openSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ordenar por',
                    style: FoodlyTheme.serifSection.copyWith(fontSize: 20),
                  ),
                ),
                RadioListTile<PlatoSearchSort>(
                  title: const Text('Relevancia'),
                  value: PlatoSearchSort.none,
                  groupValue: _sort,
                  activeColor: FoodlyColors.celeste,
                  onChanged: (value) {
                    if (value == null) return;
                    Navigator.pop(context);
                    _applySort(value);
                  },
                ),
                RadioListTile<PlatoSearchSort>(
                  title: const Text('Nombre (A-Z)'),
                  value: PlatoSearchSort.nombre,
                  groupValue: _sort,
                  activeColor: FoodlyColors.celeste,
                  onChanged: (value) {
                    if (value == null) return;
                    Navigator.pop(context);
                    _applySort(value);
                  },
                ),
                RadioListTile<PlatoSearchSort>(
                  title: const Text('Precio: menor a mayor'),
                  value: PlatoSearchSort.precioAsc,
                  groupValue: _sort,
                  activeColor: FoodlyColors.celeste,
                  onChanged: (value) {
                    if (value == null) return;
                    Navigator.pop(context);
                    _applySort(value);
                  },
                ),
                RadioListTile<PlatoSearchSort>(
                  title: const Text('Precio: mayor a menor'),
                  value: PlatoSearchSort.precioDesc,
                  groupValue: _sort,
                  activeColor: FoodlyColors.celeste,
                  onChanged: (value) {
                    if (value == null) return;
                    Navigator.pop(context);
                    _applySort(value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _sortLabel {
    switch (_sort) {
      case PlatoSearchSort.nombre:
        return 'Orden: Nombre';
      case PlatoSearchSort.precioAsc:
        return 'Orden: Precio ↑';
      case PlatoSearchSort.precioDesc:
        return 'Orden: Precio ↓';
      case PlatoSearchSort.none:
        return 'Orden';
    }
  }

  void _navigateToLocal(int localId) {
    Navigator.pushNamed(
      context,
      LocalDetailScreen.routeName,
      arguments: localId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FoodlyColors.blanco,
      appBar: AppBar(
        backgroundColor: FoodlyColors.blanco,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Buscar platos',
          style: FoodlyTheme.serifSection.copyWith(fontSize: 22),
        ),
      ),
      body: RefreshIndicator(
        color: FoodlyColors.celeste,
        onRefresh: () async => _reloadResults(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Nombre del plato...',
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
                      label: 'Todos',
                      selected: !_soloPromociones,
                      onTap: () => _setSoloPromociones(false),
                    ),
                    FoodlyFilterChip(
                      label: 'Promociones',
                      selected: _soloPromociones,
                      onTap: () => _setSoloPromociones(true),
                    ),
                    FoodlyFilterChip(
                      label: _sortLabel,
                      selected: _sort != PlatoSearchSort.none,
                      onTap: _openSortSheet,
                      showCheckmark: false,
                      trailing: const Icon(Icons.expand_more, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            if (_catalogRepository.usesMockData || ApiConstants.useMockCatalog)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _DemoChip(),
                ),
              ),
            FutureBuilder<List<PlatoBusquedaItem>>(
              future: _resultsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: PlatoListSkeleton(count: 4),
                  );
                }

                if (snapshot.hasError) {
                  final message = snapshot.error is ApiException
                      ? (snapshot.error as ApiException).userMessage
                      : snapshot.error is NetworkException
                          ? (snapshot.error as NetworkException).userMessage
                          : 'Ocurrió un error al buscar platos.';
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorState(
                      message: message,
                      onRetry: _reloadResults,
                    ),
                  );
                }

                final allItems = snapshot.data ?? [];
                final categorias = CatalogFilter.categoriasDe(
                  allItems.map((item) => item.plato).toList(),
                );
                if (_categoriaId != null &&
                    categorias.every((c) => c.id != _categoriaId)) {
                  _categoriaId = null;
                }
                final items = _categoriaId == null
                    ? allItems
                    : allItems
                        .where((item) => item.plato.categoriaId == _categoriaId)
                        .toList();

                if (allItems.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'Sin resultados',
                      subtitle: _query.trim().isEmpty
                          ? 'Probá buscar por nombre o activá el filtro de promociones.'
                          : 'No encontramos platos con esos criterios.',
                      actionLabel: 'Limpiar filtros',
                      onAction: _clearFilters,
                    ),
                  );
                }

                return SliverMainAxisGroup(
                  slivers: [
                    if (categorias.isNotEmpty)
                      SliverToBoxAdapter(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: Row(
                            children: [
                              FoodlyFilterChip(
                                label: 'Todas',
                                selected: _categoriaId == null,
                                onTap: () => _setCategoriaId(null),
                              ),
                              for (final categoria in categorias)
                                FoodlyFilterChip(
                                  label: categoria.nombre,
                                  selected: _categoriaId == categoria.id,
                                  onTap: () => _setCategoriaId(categoria.id),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.restaurant_menu_outlined,
                          title: 'Sin resultados',
                          subtitle: 'No encontramos platos en esa categoría.',
                          actionLabel: 'Limpiar filtros',
                          onAction: _clearFilters,
                        ),
                      )
                    else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          '${items.length} ${items.length == 1 ? 'plato encontrado' : 'platos encontrados'}',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: FoodlyColors.grisIntermedio,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            return PlatoBusquedaCard(
                              item: item,
                              onTap: () => _navigateToLocal(item.localId),
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
                    ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(
          'Datos de demostración',
          style: GoogleFonts.nunito(fontSize: 12),
        ),
        backgroundColor: FoodlyColors.amarillo.withValues(alpha: 0.25),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
