import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/catalog/catalog_filter.dart';
import '../core/errors/api_exception.dart';
import '../data/models/local_model.dart';
import '../data/models/plato_model.dart';
import '../data/repositories/catalog_repository.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';
import '../domain/cart/cart_notifier.dart';
import '../widgets/cart_fab.dart';
import '../widgets/plato_card.dart';

class LocalDetailScreen extends StatefulWidget {
  const LocalDetailScreen({super.key, required this.localId, this.local});

  static const routeName = '/local';

  final int localId;
  final LocalModel? local;

  @override
  State<LocalDetailScreen> createState() => _LocalDetailScreenState();
}

class _LocalDetailScreenState extends State<LocalDetailScreen> {
  final _repository = CatalogRepository();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  Object? _error;
  _LocalDetailData? _data;
  String _query = '';
  PlatoSortOption _sort = PlatoSortOption.nombre;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_LocalDetailData> _loadData() async {
    final local = widget.local ?? await _repository.obtenerLocal(widget.localId);
    if (local == null) {
      throw const ApiException(
        statusCode: 404,
        userMessage: 'El local solicitado no existe.',
      );
    }
    final platos = await _repository.platosDeLocal(widget.localId);
    return _LocalDetailData(local: local, platos: platos);
  }

  Future<void> _load() async {
    try {
      final data = await _loadData();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _data = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      final data = await _loadData();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (_) {}
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
        SnackBar(content: Text('${plato.nombre} agregado al carrito')),
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
          SnackBar(content: Text('${plato.nombre} agregado al carrito')),
        );
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      final message = _error is ApiException
          ? (_error as ApiException).userMessage
          : _error is NetworkException
              ? (_error as NetworkException).userMessage
              : 'Ocurrió un error al cargar el local.';
      return _MessageState(
        message: message,
        onRetry: () {
          setState(() {
            _isLoading = true;
            _error = null;
          });
          _load();
        },
      );
    }

    final data = _data!;
    final platos = CatalogFilter.filterPlatos(
      platos: data.platos,
      localId: widget.localId,
      query: _query,
      sort: _sort,
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.local.nombre,
                  style: FoodlyTheme.serifTitle.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  data.local.descripcion,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: FoodlyColors.grisIntermedio,
                  ),
                ),
                if (!data.local.estaAbierto) ...[
                  const SizedBox(height: 12),
                  _ClosedBanner(),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar plato...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PlatoSortOption>(
                  initialValue: _sort,
                  decoration: const InputDecoration(
                    labelText: 'Ordenar por',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: PlatoSortOption.nombre,
                      child: Text('Nombre'),
                    ),
                    DropdownMenuItem(
                      value: PlatoSortOption.precio,
                      child: Text('Precio'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _sort = value);
                  },
                ),
              ],
            ),
          ),
        ),
        if (platos.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _MessageState(
              message: 'No se encontraron platos o promociones que coincidan con su búsqueda.',
              onRetry: _query.isNotEmpty ? () => _searchController.clear() : null,
              retryLabel: 'Limpiar búsqueda',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const CartFab(),
      appBar: AppBar(
        title: Text(
          _data?.local.nombre ?? 'Platos',
          style: FoodlyTheme.serifTitle.copyWith(fontSize: 22),
        ),
        backgroundColor: FoodlyColors.blanco,
        foregroundColor: FoodlyColors.grisOscuro,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildBody(),
      ),
    );
  }
}

class _LocalDetailData {
  const _LocalDetailData({required this.local, required this.platos});

  final LocalModel local;
  final List<PlatoModel> platos;
}

class _ClosedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FoodlyColors.grisClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Este local está cerrado y no acepta pedidos por el momento.',
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: FoodlyColors.grisOscuro,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.onRetry, this.retryLabel = 'Reintentar'});

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

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
              TextButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
