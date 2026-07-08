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
  final monto = TextEditingController();
  final compensacion = TextEditingController();
  var tipoCompensacion = TipoCompensacionSolicitada.reintegro;

  return showDialog<ReclamoFormData?>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final esReintegro =
            tipoCompensacion == TipoCompensacionSolicitada.reintegro;

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
                const SizedBox(height: 12),
                if (esReintegro)
                  TextField(
                    controller: monto,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Monto de reintegro *',
                      hintText: 'Máximo \$${pedido.total.toStringAsFixed(0)}',
                    ),
                  )
                else
                  TextField(
                    controller: compensacion,
                    decoration: const InputDecoration(
                      labelText: 'Compensación alternativa *',
                      hintText: 'Ej: reenvío del pedido, descuento...',
                    ),
                    maxLines: 2,
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

                if (esReintegro) {
                  final error = ReclamoRules.validarMontoReintegro(
                    rawMonto: monto.text,
                    totalPedido: pedido.total,
                  );
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                    return;
                  }
                } else {
                  final error = ReclamoRules.validarCompensacionAlternativa(
                    compensacion.text,
                  );
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                    return;
                  }
                }

                Navigator.pop(
                  context,
                  ReclamoFormData(
                    motivo: motivo.text.trim(),
                    tipoCompensacion: esReintegro
                        ? ReclamoRules.tipoReintegro
                        : compensacion.text.trim(),
                    montoReintegro: esReintegro
                        ? double.parse(
                            monto.text.trim().replaceAll(',', '.'),
                          )
                        : null,
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
