import 'package:flutter/material.dart';

import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class CalificarFormResult {
  const CalificarFormResult({
    required this.puntaje,
    required this.comentario,
  });

  final int puntaje;
  final String comentario;
}

/// Diálogo reutilizable para calificar o editar calificación de un local (CU-CL10).
Future<CalificarFormResult?> showCalificarDialog({
  required BuildContext context,
  required String localNombre,
  int puntajeInicial = 0,
  String comentarioInicial = '',
  bool esEdicion = false,
}) {
  return showDialog<CalificarFormResult>(
    context: context,
    builder: (context) => CalificarDialog(
      localNombre: localNombre,
      puntajeInicial: puntajeInicial,
      comentarioInicial: comentarioInicial,
      esEdicion: esEdicion,
    ),
  );
}

class CalificarDialog extends StatefulWidget {
  const CalificarDialog({
    super.key,
    required this.localNombre,
    this.puntajeInicial = 0,
    this.comentarioInicial = '',
    this.esEdicion = false,
  });

  final String localNombre;
  final int puntajeInicial;
  final String comentarioInicial;
  final bool esEdicion;

  @override
  State<CalificarDialog> createState() => _CalificarDialogState();
}

class _CalificarDialogState extends State<CalificarDialog> {
  late int _puntaje;
  late final TextEditingController _comentario;

  @override
  void initState() {
    super.initState();
    _puntaje = widget.puntajeInicial;
    _comentario = TextEditingController(text: widget.comentarioInicial);
  }

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.esEdicion ? 'Editar calificación' : 'Calificar local'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.localNombre,
              style: FoodlyTheme.sansBlack.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _puntaje = star),
                  icon: Icon(
                    star <= _puntaje ? Icons.star : Icons.star_border,
                    color: FoodlyColors.amarillo,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comentario,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (_puntaje == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Seleccioná un puntaje de 1 a 5.'),
                ),
              );
              return;
            }
            Navigator.pop(
              context,
              CalificarFormResult(
                puntaje: _puntaje,
                comentario: _comentario.text,
              ),
            );
          },
          child: Text(widget.esEdicion ? 'Guardar' : 'Enviar'),
        ),
      ],
    );
  }
}
