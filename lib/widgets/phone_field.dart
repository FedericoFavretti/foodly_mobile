import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/validators/form_validators.dart';
import '../core/validators/phone_codes.dart';
import '../theme/foodly_colors.dart';

/// Input compuesto de celular: selector de código de país + número.
///
/// El valor que expone (vía [FormFieldState.value] / `onChanged`) es
/// siempre el string E.164 completo (ej. `+598991234567`), nunca las
/// partes separadas — igual que el `PhoneField` de la web. Si el número
/// queda vacío, el valor es `""` (campo opcional).
class PhoneField extends FormField<String> {
  PhoneField({
    super.key,
    String initialValue = '',
    bool enabled = true,
    ValueChanged<String>? onChanged,
    String label = 'Celular (opcional)',
  }) : super(
          initialValue: initialValue,
          validator: FormValidators.celular,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          builder: (state) {
            return _PhoneFieldInput(
              state: state,
              enabled: enabled,
              label: label,
              onChanged: onChanged,
            );
          },
        );
}

class _PhoneFieldInput extends StatefulWidget {
  const _PhoneFieldInput({
    required this.state,
    required this.enabled,
    required this.label,
    required this.onChanged,
  });

  final FormFieldState<String> state;
  final bool enabled;
  final String label;
  final ValueChanged<String>? onChanged;

  @override
  State<_PhoneFieldInput> createState() => _PhoneFieldInputState();
}

class _PhoneFieldInputState extends State<_PhoneFieldInput> {
  late PhoneCountry _country;
  late final TextEditingController _numberController;

  @override
  void initState() {
    super.initState();
    final split = PhoneCodes.split(widget.state.value);
    _country = split.country;
    _numberController = TextEditingController(text: split.number);
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  String get _composedValue =>
      _numberController.text.isEmpty ? '' : '${_country.code}${_numberController.text}';

  void _emit() {
    final value = _composedValue;
    widget.state.didChange(value);
    widget.onChanged?.call(value);
  }

  void _onCountryChanged(PhoneCountry? country) {
    if (country == null) return;
    setState(() => _country = country);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final errorText = widget.state.errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: FoodlyColors.grisIntermedio,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: errorText != null
                      ? Theme.of(context).colorScheme.error
                      : FoodlyColors.grisClaro,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              height: 48,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PhoneCountry>(
                  value: _country,
                  isDense: true,
                  onChanged: widget.enabled ? _onCountryChanged : null,
                  items: [
                    for (final country in PhoneCodes.all)
                      DropdownMenuItem(
                        value: country,
                        child: Text(
                          '${country.flag} ${country.code}',
                          style: GoogleFonts.nunito(fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _numberController,
                enabled: widget.enabled,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Número',
                  errorText: errorText,
                ),
                onChanged: (_) => _emit(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
