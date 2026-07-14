import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/catalog/catalog_filter.dart';
import '../core/constants/api_constants.dart';
import '../core/errors/api_exception.dart';
import '../data/models/cliente_profile_model.dart';
import '../data/models/local_model.dart';
import '../data/repositories/catalog_repository.dart';
import '../domain/catalog/local_list_filter.dart';
import '../domain/session/session_manager.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/foodly_filter_chip.dart';
import '../widgets/local_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/wavy_accent.dart';
import 'local_detail_screen.dart';
import 'platos_search_screen.dart';

enum _FiltroRapido { todos, abiertos, mejorCalificados }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const routeName = '/app';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _catalogRepository = CatalogRepository();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  Object? _error;
  List<LocalModel>? _data;
  String _query = '';
  _FiltroRapido _filtroRapido = _FiltroRapido.todos;
  LocalSortOption _sort = LocalSortOption.nombre;
  String? _nombreCliente;
  Timer? _searchDebounce;

  LocalListFilter get _activeFilter => LocalListFilter.fromUi(
        query: _query,
        soloAbiertos: _soloAbiertos,
        sort: _sortActivo,
      );

  @override
  void initState() {
    super.initState();
    _localesFuture = _catalogRepository.listarLocales(filter: _activeFilter);
    _searchController.addListener(_onSearchChanged);
    _loadNombreCliente();
  }

  void _onSearchChanged() {
    final nextQuery = _searchController.text;
    if (nextQuery == _query) return;
    setState(() => _query = nextQuery);

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _reloadLocales);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNombreCliente() async {
    final profileJson = await SessionManager.getProfileJson();
    if (profileJson != null) {
      try {
        final profile = ClienteProfileModel.fromJson(
          jsonDecode(profileJson) as Map<String, dynamic>,
        );
        final nombre = profile.nombre.trim();
        if (nombre.isNotEmpty && mounted) {
          setState(() => _nombreCliente = nombre);
          return;
        }
      } catch (_) {}
    }
  }

  Future<void> _reloadLocales() async {
    final filter = _activeFilter;
    setState(() {
      _localesFuture = _catalogRepository.listarLocales(filter: filter);
    });
    await _localesFuture;
  }

  void _applyFiltroRapido(_FiltroRapido filtro) {
    setState(() => _filtroRapido = filtro);
    _reloadLocales();
  }

  void _applySort(LocalSortOption sort) {
    setState(() {
      _sort = sort;
      if (_filtroRapido == _FiltroRapido.mejorCalificados) {
        _filtroRapido = _FiltroRapido.todos;
      }
    });
    _reloadLocales();
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    setState(() {
      _searchController.clear();
      _query = '';
      _filtroRapido = _FiltroRapido.todos;
      _sort = LocalSortOption.nombre;
    });
    _reloadLocales();
  }

  bool get _soloAbiertos => _filtroRapido == _FiltroRapido.abiertos;

  LocalSortOption get _sortActivo {
    if (_filtroRapido == _FiltroRapido.mejorCalificados) {
      return LocalSortOption.calificacion;
    }
    return _sort;
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
                RadioListTile<LocalSortOption>(
                  title: const Text('Nombre'),
                  value: LocalSortOption.nombre,
                  groupValue: _sort,
                  activeColor: FoodlyColors.celeste,
                  onChanged: (value) {
                    if (value == null) return;
                    Navigator.pop(context);
                    _applySort(value);
                  },
                ),
                RadioListTile<LocalSortOption>(
                  title: const Text('Calificación'),
                  value: LocalSortOption.calificacion,
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

  void _navigateToLocal(int localId) {
    Navigator.pushNamed(
      context,
      LocalDetailScreen.routeName,
      arguments: localId,
    );
  }

  void _openPlatosSearch() {
    Navigator.pushNamed(context, PlatosSearchScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FoodlyColors.blanco,
      body: RefreshIndicator(
        color: FoodlyColors.celeste,
        onRefresh: _reloadLocales,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _CatalogHero(nombreCliente: _nombreCliente)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _PlatosSearchBanner(onTap: _openPlatosSearch),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar local...',
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
                      selected: _filtroRapido == _FiltroRapido.todos,
                      onTap: () => _applyFiltroRapido(_FiltroRapido.todos),
                    ),
                    FoodlyFilterChip(
                      label: 'Abiertos',
                      selected: _filtroRapido == _FiltroRapido.abiertos,
                      onTap: () => _applyFiltroRapido(_FiltroRapido.abiertos),
                    ),
                    FoodlyFilterChip(
                      label: 'Mejor calificados',
                      selected:
                          _filtroRapido == _FiltroRapido.mejorCalificados,
                      onTap: () =>
                          _applyFiltroRapido(_FiltroRapido.mejorCalificados),
                    ),
                    FoodlyFilterChip(
                      label: _sortActivo == LocalSortOption.calificacion
                          ? 'Orden: Calificación'
                          : 'Orden: Nombre',
                      selected: false,
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
            FutureBuilder<List<LocalModel>>(
              future: _localesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: LocalListSkeleton(count: 3),
                  );
                }

                if (snapshot.hasError) {
                  final message = snapshot.error is ApiException
                      ? (snapshot.error as ApiException).userMessage
                      : snapshot.error is NetworkException
                          ? (snapshot.error as NetworkException).userMessage
                          : 'Ocurrió un error al cargar los locales.';
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorState(
                      message: message,
                      onRetry: _reloadLocales,
                    ),
                  );
                }

                final allLocales = snapshot.data ?? [];
                final destacados = CatalogFilter.destacados(locales: allLocales);
                final locales = allLocales;

                return SliverMainAxisGroup(
                  slivers: [
                    if (destacados.isNotEmpty && _query.trim().isEmpty)
                      SliverToBoxAdapter(
                        child: _FeaturedSection(
                          locales: destacados,
                          onLocalTap: _navigateToLocal,
                        ),
                      ),
                    if (locales.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.storefront_outlined,
                          title: 'Sin resultados',
                          subtitle:
                              'No se encontraron locales con esos criterios.',
                          actionLabel: 'Limpiar filtros',
                          onAction: _clearFilters,
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            '${locales.length} ${locales.length == 1 ? 'local disponible' : 'locales disponibles'}',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: FoodlyColors.grisIntermedio,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverList.separated(
                          itemCount: locales.length,
                          separatorBuilder: (context, _) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final local = locales[index];
                            return LocalCard(
                              local: local,
                              onTap: local.estaAbierto
                                  ? () => _navigateToLocal(local.id)
                                  : null,
                            );
                          },
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

class _CatalogHero extends StatelessWidget {
  const _CatalogHero({this.nombreCliente});

  final String? nombreCliente;

  @override
  Widget build(BuildContext context) {
    final saludo = nombreCliente != null && nombreCliente!.isNotEmpty
        ? 'Hola, $nombreCliente'
        : '¡Hola!';
    final topInset = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: FoodlyColors.celeste,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foodly',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    color: FoodlyColors.blanco,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  saludo,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 32,
                    height: 1.1,
                    color: FoodlyColors.blanco,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '¿Qué te provoca hoy?',
                  style: FoodlyTheme.sansBold.copyWith(
                    fontSize: 17,
                    color: FoodlyColors.amarillo,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: WavyAccent(),
            ),
          ),
          Container(
            height: 24,
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

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({
    required this.locales,
    required this.onLocalTap,
  });

  final List<LocalModel> locales;
  final void Function(int localId) onLocalTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Destacados',
              style: FoodlyTheme.serifSection.copyWith(fontSize: 20),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: locales.length,
              separatorBuilder: (context, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final local = locales[index];
                return LocalCard(
                  local: local,
                  variant: LocalCardVariant.featured,
                  onTap: () => onLocalTap(local.id),
                );
              },
            ),
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

class _PlatosSearchBanner extends StatelessWidget {
  const _PlatosSearchBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FoodlyColors.amarillo.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FoodlyColors.celeste.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: FoodlyColors.celeste,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buscar platos',
                      style: FoodlyTheme.sansBlack.copyWith(
                        fontSize: 16,
                        color: FoodlyColors.grisOscuro,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Encontrá promos en todos los locales',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: FoodlyColors.grisIntermedio,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: FoodlyColors.grisIntermedio,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
