import 'package:flutter/material.dart';

import '../core/providers/notificacion_notifier.dart';
import '../data/models/notificacion_model.dart';
import '../theme/foodly_colors.dart';
import 'order_status_screen.dart';
import '../data/repositories/pedido_repository.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({
    super.key,
    required this.notifier,
  });

  static const routeName = '/notificaciones';

  final NotificacionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FoodlyColors.grisClaro,
      appBar: AppBar(
        backgroundColor: FoodlyColors.blanco,
        elevation: 0,
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: FoodlyColors.negro,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: notifier,
            builder: (_, __) {
              if (notifier.noLeidasCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: notifier.marcarTodasLeidas,
                child: Text(
                  'Marcar todas leídas',
                  style: TextStyle(
                    color: FoodlyColors.celeste,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: notifier,
        builder: (context, _) {
          final notificaciones = notifier.notificaciones;

          if (notificaciones.isEmpty) {
            return _EmptyState(onRefresh: notifier.refresh);
          }

          return RefreshIndicator(
            color: FoodlyColors.celeste,
            onRefresh: notifier.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: notificaciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 1),
              itemBuilder: (context, index) {
                final n = notificaciones[index];
                return _NotificacionTile(
                  notificacion: n,
                  onTap: () => _handleTap(context, n),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleTap(
      BuildContext context, NotificacionModel n) async {
    if (!n.leida) {
      await notifier.marcarLeida(n.id);
    }

    if (!context.mounted) return;

    if (n.pedidoId != null) {
      _navigateToPedido(context, n.pedidoId!);
    }
  }

  Future<void> _navigateToPedido(BuildContext context, int pedidoId) async {
    try {
      final repo = PedidoRepository();
      final pedido = await repo.obtenerPedido(pedidoId);
      if (!context.mounted) return;
      Navigator.pushNamed(context, OrderStatusScreen.routeName,
          arguments: pedido);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el pedido.')),
      );
    }
  }
}

// ──────────────────────────────────────────────────────────────
// Tile de notificación
// ──────────────────────────────────────────────────────────────

class _NotificacionTile extends StatelessWidget {
  const _NotificacionTile({
    required this.notificacion,
    required this.onTap,
  });

  final NotificacionModel notificacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notificacion;
    final noLeida = !n.leida;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: noLeida
            ? FoodlyColors.celeste.withValues(alpha: 0.06)
            : FoodlyColors.blanco,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TipoIcon(tipo: n.tipo, noLeida: noLeida),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (noLeida)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6, top: 2),
                          decoration: const BoxDecoration(
                            color: FoodlyColors.celeste,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          n.mensaje,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: noLeida
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: FoodlyColors.negro,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.fechaFormateada,
                    style: const TextStyle(
                      fontSize: 12,
                      color: FoodlyColors.grisOscuro,
                    ),
                  ),
                ],
              ),
            ),
            if (n.pedidoId != null)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  Icons.chevron_right,
                  color: FoodlyColors.grisOscuro,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Ícono según tipo de notificación
// ──────────────────────────────────────────────────────────────

class _TipoIcon extends StatelessWidget {
  const _TipoIcon({required this.tipo, required this.noLeida});

  final String tipo;
  final bool noLeida;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (tipo.toLowerCase()) {
      case 'pedido':
        icon = Icons.receipt_long;
        color = FoodlyColors.celeste;
        break;
      case 'reclamo':
        icon = Icons.support_agent;
        color = Colors.orange;
        break;
      case 'local':
        icon = Icons.storefront;
        color = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        color = FoodlyColors.grisOscuro;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Estado vacío
// ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: FoodlyColors.celeste,
      onRefresh: onRefresh,
      child: ListView(
        children: const [
          SizedBox(height: 80),
          Column(
            children: [
              Icon(
                Icons.notifications_none_outlined,
                size: 72,
                color: FoodlyColors.grisIntermedio,
              ),
              SizedBox(height: 16),
              Text(
                'Sin notificaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: FoodlyColors.grisOscuro,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Cuando tengas novedades sobre\ntus pedidos te avisaremos aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
