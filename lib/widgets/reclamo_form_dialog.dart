import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/models/pedido_response_model.dart';
import '../domain/reclamo/reclamo_form_data.dart';
import '../domain/reclamo/reclamo_rules.dart';
import '../theme/foodly_colors.dart';

/// Diálogo reutilizable para crear un reclamo (historial + tab Reclamos).
Future<ReclamoFormData?> showReclamoFormDialog(
  BuildContext context, {
  required PedidoResponseModel pedido,
}) {
  final motivo = TextEditingController();
  var tipoCompensacion = TipoCompensacionSolicitada.reintegro;

  return showDialog<ReclamoFormData?>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Realizar reclamo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pedido Nº ${pedido.id} — ${pedido.localNombre}',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: FoodlyColors.grisIntermedio,
                  ),
                ),
                Text(
                  'Total del pedido: \$${pedido.total.toStringAsFixed(0)}',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: motivo,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del reclamo *',
                    hintText: 'Describí el problema...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Compensación solicitada *',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<TipoCompensacionSolicitada>(
                  segments: const [
                    ButtonSegment(
                      value: TipoCompensacionSolicitada.reintegro,
                      label: Text('Reintegro'),
                    ),
                    ButtonSegment(
                      value: TipoCompensacionSolicitada.alternativa,
                      label: Text('Otra'),
                    ),
                  ],
                  selected: {tipoCompensacion},
                  onSelectionChanged: (selection) {
                    setDialogState(() {
                      tipoCompensacion = selection.first;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (motivo.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Debe describir el motivo del reclamo antes de enviarlo.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  context,
                  ReclamoFormData(
                    motivo: motivo.text.trim(),
                    tipoCompensacion:
                        tipoCompensacion == TipoCompensacionSolicitada.reintegro
                            ? ReclamoRules.tipoReintegro
                            : ReclamoRules.tipoAlternativa,
                  ),
                );
              },
              child: const Text('Enviar reclamo'),
            ),
          ],
        );
      },
    ),
  );
}
