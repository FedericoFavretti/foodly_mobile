import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/pedido_response_model.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class PedidoCard extends StatefulWidget {
  const PedidoCard({
    super.key,
    required this.pedido,
    this.onCancel,
    this.onReclamar,
    this.reclamoEnviado = false,
    this.onCalificar,
    this.calificarLabel,
    this.onReintentarPago,
  });

  final PedidoResponseModel pedido;
  final VoidCallback? onCancel;
  final VoidCallback? onReclamar;
  final bool reclamoEnviado;
  final VoidCallback? onCalificar;
  final String? calificarLabel;
  /// Callback para reintentar pago MP desde el historial.
  /// Cuando está presente se muestra el botón "Reintentar pago".
  final VoidCallback? onReintentarPago;

  @override
  State<PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<PedidoCard> {
  bool _expanded = false;

  PedidoResponseModel get pedido => widget.pedido;

  Color _estadoColor() {
    switch (pedido.estado) {
      case 'Pendiente':
        return FoodlyColors.amarillo;
      case 'Confirmado':
        return FoodlyColors.celeste;
      case 'Entregado':
        return const Color(0xFF2E7D32);
      case 'Cancelado':
        return FoodlyColors.grisIntermedio;
      case 'Rechazado':
        return const Color(0xFFD32F2F);
      default:
        return FoodlyColors.grisIntermedio;
    }
  }

  IconData _estadoIcon() {
    switch (pedido.estado) {
      case 'Pendiente':
        return Icons.schedule;
      case 'Confirmado':
        return Icons.check_circle_outline;
      case 'Entregado':
        return Icons.delivery_dining;
      case 'Cancelado':
        return Icons.cancel_outlined;
      case 'Rechazado':
        return Icons.block;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Future<void> _abrirMercadoPago() async {
    final uri = Uri.tryParse(pedido.mpInitPoint!.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _estadoColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: FoodlyColors.blanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FoodlyColors.grisOscuro.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pedido.localNombre,
                        style: FoodlyTheme.sansBlack.copyWith(
                          fontSize: 17,
                          color: FoodlyColors.grisOscuro,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pedido Nº ${pedido.id}',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: FoodlyColors.grisIntermedio,
                        ),
                      ),
                      if (pedido.fechaLegible != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          pedido.fechaLegible!,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: FoodlyColors.grisIntermedio,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _EstadoBadge(
                  label: pedido.estado,
                  color: estadoColor,
                  icon: _estadoIcon(),
                ),
              ],
            ),
            if (_mostrarTimeline) ...[
              const SizedBox(height: 14),
              _PedidoTimeline(estado: pedido.estado),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (pedido.medioPagoLabel != null)
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    label: pedido.medioPagoLabel!,
                  ),
                if (_mostrarTiempoEntrega)
                  _InfoChip(
                    icon: Icons.schedule_outlined,
                    label:
                        'Entrega estimada: ${pedido.tiempoEntregaMinutos} min',
                  ),
                _InfoChip(
                  icon: Icons.attach_money,
                  label: '\$${pedido.total.toStringAsFixed(0)}',
                  emphasized: true,
                ),
              ],
            ),
            if (pedido.estado == 'Rechazado' &&
                pedido.motivoRechazo != null) ...[
              const SizedBox(height: 12),
              _MotivoRechazoBox(motivo: pedido.motivoRechazo!),
            ],
            if (pedido.detalles.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        _expanded
                            ? 'Ocultar detalle'
                            : 'Ver ${pedido.detalles.length} ${pedido.detalles.length == 1 ? 'ítem' : 'ítems'}',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: FoodlyColors.celeste,
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: FoodlyColors.celeste,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                ...pedido.detalles.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${d.cantidad}x ${d.platoNombre}',
                            style: GoogleFonts.nunito(fontSize: 13),
                          ),
                        ),
                        Text(
                          '\$${d.subtotal.toStringAsFixed(0)}',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            if (pedido.puedeCompletarPagoMercadoPago) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _abrirMercadoPago,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Completar pago'),
                style: FilledButton.styleFrom(
                  backgroundColor: FoodlyColors.amarillo,
                  foregroundColor: FoodlyColors.grisOscuro,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
            if (_tieneAcciones) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.onCancel != null)
                    _ActionButton(
                      label: 'Cancelar pedido',
                      icon: Icons.close,
                      foreground: const Color(0xFFD32F2F),
                      onPressed: widget.onCancel,
                    ),
                  if (widget.onReclamar != null)
                    _ActionButton(
                      label: 'Reclamar',
                      icon: Icons.report_outlined,
                      onPressed: widget.onReclamar,
                    )
                  else if (widget.reclamoEnviado)
                    _ActionButton(
                      label: 'Reclamo enviado',
                      icon: Icons.check,
                      enabled: false,
                    ),
                  if (widget.onCalificar != null)
                    _ActionButton(
                      label: widget.calificarLabel ?? 'Calificar',
                      icon: Icons.star_border,
                      foreground: FoodlyColors.celeste,
                      onPressed: widget.onCalificar,
                    ),
                  if (widget.onReintentarPago != null)
                    _ActionButton(
                      label: 'Reintentar pago',
                      icon: Icons.payment,
                      foreground: FoodlyColors.amarillo,
                      onPressed: widget.onReintentarPago,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _mostrarTimeline {
    final estado = pedido.estado.toLowerCase();
    return estado == 'pendiente' ||
        estado == 'confirmado' ||
        estado == 'entregado';
  }

  bool get _mostrarTiempoEntrega {
    if (!pedido.tieneTiempoEntrega) return false;
    final estado = pedido.estadoNormalizado.toLowerCase();
    return estado == 'confirmado' || estado == 'entregado';
  }

  bool get _tieneAcciones =>
      widget.onCancel != null ||
      widget.onReclamar != null ||
      widget.reclamoEnviado ||
      widget.onCalificar != null ||
      widget.onReintentarPago != null;
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized
            ? FoodlyColors.celeste.withValues(alpha: 0.1)
            : FoodlyColors.grisClaro,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: emphasized ? FoodlyColors.celeste : FoodlyColors.grisIntermedio,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: emphasized
                  ? FoodlyColors.celeste
                  : FoodlyColors.grisIntermedio,
            ),
          ),
        ],
      ),
    );
  }
}

class _MotivoRechazoBox extends StatelessWidget {
  const _MotivoRechazoBox({required this.motivo});

  final String motivo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD32F2F).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Motivo del rechazo',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFD32F2F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            motivo,
            style: GoogleFonts.nunito(
              fontSize: 13,
              height: 1.35,
              color: FoodlyColors.grisOscuro,
            ),
          ),
        ],
      ),
    );
  }
}

class _PedidoTimeline extends StatelessWidget {
  const _PedidoTimeline({required this.estado});

  final String estado;

  int get _step {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 0;
      case 'confirmado':
        return 1;
      case 'entregado':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Pendiente', 'Confirmado', 'Entregado'];

    return Row(
      children: List.generate(labels.length * 2 - 1, (index) {
        if (index.isOdd) {
          final lineIndex = index ~/ 2;
          final active = lineIndex < _step;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(bottom: 18),
              color: active
                  ? FoodlyColors.celeste
                  : FoodlyColors.grisClaro,
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final active = stepIndex <= _step;
        final current = stepIndex == _step;

        return Column(
          children: [
            Container(
              width: current ? 22 : 18,
              height: current ? 22 : 18,
              decoration: BoxDecoration(
                color: active ? FoodlyColors.celeste : FoodlyColors.grisClaro,
                shape: BoxShape.circle,
                border: current
                    ? Border.all(color: FoodlyColors.celeste, width: 3)
                    : null,
              ),
              child: active
                  ? Icon(
                      Icons.check,
                      size: current ? 12 : 10,
                      color: FoodlyColors.blanco,
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              labels[stepIndex],
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                color: active
                    ? FoodlyColors.celeste
                    : FoodlyColors.grisIntermedio,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.foreground,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? foreground;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = foreground ?? FoodlyColors.grisOscuro;

    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 16, color: enabled ? color : FoodlyColors.grisIntermedio),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: enabled ? color.withValues(alpha: 0.35) : FoodlyColors.grisClaro,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
