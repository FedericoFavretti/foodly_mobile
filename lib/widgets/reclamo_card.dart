import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/reclamo_listado_model.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class ReclamoCard extends StatelessWidget {
  const ReclamoCard({super.key, required this.reclamo});

  final ReclamoListadoModel reclamo;

  Color _estadoColor() {
    return reclamo.esAtendido
        ? const Color(0xFF2E7D32)
        : FoodlyColors.amarillo;
  }

  IconData _estadoIcon() {
    return reclamo.esAtendido ? Icons.check_circle : Icons.hourglass_top;
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
                        reclamo.localNombre,
                        style: FoodlyTheme.sansBlack.copyWith(
                          fontSize: 17,
                          color: FoodlyColors.grisOscuro,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reclamo Nº ${reclamo.id} · Pedido Nº ${reclamo.pedidoId}',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: FoodlyColors.grisIntermedio,
                        ),
                      ),
                      if (reclamo.fechaLegible != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          reclamo.fechaLegible!,
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
                  label: reclamo.estado,
                  color: estadoColor,
                  icon: _estadoIcon(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ReclamoTimeline(atendido: reclamo.esAtendido),
            const SizedBox(height: 14),
            _SectionBox(
              title: reclamo.esAtendido ? 'Respuesta del local' : 'Tu reclamo',
              icon: reclamo.esAtendido
                  ? Icons.support_agent_outlined
                  : Icons.report_problem_outlined,
              child: Text(
                reclamo.motivo,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: FoodlyColors.grisOscuro,
                  height: 1.4,
                ),
              ),
            ),
            if (reclamo.compensacionLabel != null ||
                reclamo.montoReintegro != null) ...[
              const SizedBox(height: 10),
              _SectionBox(
                title: reclamo.esAtendido
                    ? 'Resolución'
                    : 'Compensación solicitada',
                icon: Icons.handshake_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reclamo.compensacionLabel != null)
                      Text(
                        reclamo.compensacionLabel!,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: FoodlyColors.grisOscuro,
                        ),
                      ),
                    if (reclamo.montoReintegro != null &&
                        (reclamo.compensacionLabel?.toLowerCase() == 'reintegro' ||
                            reclamo.tipoCompensacion?.toLowerCase() ==
                                'reintegro')) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Monto: \$${reclamo.montoReintegro!.toStringAsFixed(0)}',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: FoodlyColors.grisIntermedio,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (reclamo.pedidoTotal != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (reclamo.pedidoEstado != null)
                    _InfoChip(
                      icon: Icons.receipt_long_outlined,
                      label: 'Pedido ${reclamo.pedidoEstado!}',
                    ),
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    label:
                        'Total pedido \$${reclamo.pedidoTotal!.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
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
        borderRadius: BorderRadius.circular(20),
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
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReclamoTimeline extends StatelessWidget {
  const _ReclamoTimeline({required this.atendido});

  final bool atendido;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TimelineStep(
          label: 'Enviado',
          active: true,
          completed: true,
        ),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 18),
            color: atendido
                ? FoodlyColors.celeste
                : FoodlyColors.grisClaro,
          ),
        ),
        _TimelineStep(
          label: 'Atendido',
          active: atendido,
          completed: atendido,
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.active,
    required this.completed,
  });

  final String label;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? FoodlyColors.celeste
        : active
            ? FoodlyColors.amarillo
            : FoodlyColors.grisClaro;

    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? color : FoodlyColors.blanco,
            border: Border.all(color: color, width: 2),
          ),
          child: completed
              ? const Icon(Icons.check, size: 12, color: FoodlyColors.blanco)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? FoodlyColors.grisOscuro : FoodlyColors.grisIntermedio,
          ),
        ),
      ],
    );
  }
}

class _SectionBox extends StatelessWidget {
  const _SectionBox({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FoodlyColors.grisClaro.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: FoodlyColors.celeste),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: FoodlyColors.grisIntermedio,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: FoodlyColors.grisClaro),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: FoodlyColors.grisIntermedio),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: FoodlyColors.grisIntermedio,
            ),
          ),
        ],
      ),
    );
  }
}
