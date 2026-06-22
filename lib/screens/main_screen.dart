import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/catalog/catalog_filter.dart';
import '../core/constants/api_constants.dart';
import '../core/errors/api_exception.dart';
import '../data/models/local_model.dart';
import '../data/repositories/catalog_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../widgets/local_card.dart';
import 'local_detail_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const routeName = '/app';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _catalogRepository = CatalogRepository();
  final _searchController = TextEditingController();

  late Future<List<LocalModel>> _localesFuture;
  String _query = '';
  bool _soloAbiertos = false;
  LocalSortOption _sort = LocalSortOption.nombre;

  @override
  void initState() {
    super.initState();
    _localesFuture = _catalogRepository.listarLocales();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadLocales() {
    setState(() {
      _localesFuture = _catalogRepository.listarLocales();
    });
  }

  Future<void> _refreshLocales() async {
    final future = _catalogRepository.listarLocales();
    setState(() => _localesFuture = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshLocales,
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola!',
                    style: FoodlyTheme.serifTitle.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explorá locales y pedí lo que más te guste.',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: FoodlyColors.grisIntermedio,
                    ),
                  ),
                  if (_catalogRepository.usesMockData ||
                      ApiConstants.useMockCatalog) ...[
                    const SizedBox(height: 12),
                    const _DemoChip(),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar local...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Solo abiertos'),
                        selected: _soloAbiertos,
                        onSelected: (value) {
                          setState(() => _soloAbiertos = value);
                        },
                      ),
                      const Spacer(),
                      DropdownButton<LocalSortOption>(
                        value: _sort,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: LocalSortOption.nombre,
                            child: Text('Nombre'),
                          ),
                          DropdownMenuItem(
                            value: LocalSortOption.calificacion,
                            child: Text('Calificación'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _sort = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          FutureBuilder(
            future: _localesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
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
                  child: _ErrorState(
                    message: message,
                    onRetry: _reloadLocales,
                  ),
                );
              }

              final locales = CatalogFilter.filterLocales(
                locales: snapshot.data!,
                query: _query,
                soloAbiertos: _soloAbiertos,
                sort: _sort,
              );

              if (locales.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    message:
                        'No se encontraron locales que coincidan con su búsqueda. Intente con otros criterios.',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final local = locales[index];
                      return LocalCard(
                        local: local,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            LocalDetailScreen.routeName,
                            arguments: local.id,
                          );
                        },
                      );
                    },
                    childCount: locales.length,
                  ),
                ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: FoodlyColors.grisIntermedio,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
