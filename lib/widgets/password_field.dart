import 'package:flutter/material.dart';

import '../core/validators/form_validators.dart';
import '../theme/foodly_colors.dart';
import '../theme/foodly_theme.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
  });

  final String label;
  final List<String>? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          autofillHints: widget.label.toLowerCase().contains('confirmar')
              ? const [AutofillHints.newPassword]
              : const [AutofillHints.password],
          validator: widget.validator ??
              (value) {
                if (widget.hint != null) {
                  return FormValidators.password(value);
                }
                if (value == null || value.isEmpty) {
                  return 'Ingresá tu contraseña.';
                }
                return null;
              },
          decoration: InputDecoration(
            hintText: widget.label,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: FoodlyColors.grisIntermedio,
              ),
            ),
          ),
        ),
        if (widget.hint != null) ...[
          const SizedBox(height: 8),
          Text(
            'La contraseña debe tener:',
            style: FoodlyTheme.sansBold.copyWith(
              fontSize: 12,
              color: FoodlyColors.grisIntermedio,
            ),
          ),
          const SizedBox(height: 4),
          ...widget.hint!.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Text(
                '• $item',
                style: TextStyle(
                  fontSize: 12,
                  color: FoodlyColors.grisIntermedio.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
