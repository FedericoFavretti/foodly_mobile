/// Formateo de teléfonos para mostrar en UI (equivalente a `phone.js` web).
abstract final class PhoneFormat {
  static const telefonoFijoPrefix = '+598';

  /// El teléfono fijo de un Local siempre es de Uruguay — se muestra sin
  /// el prefijo `+598` porque es ruido (siempre es el mismo). El valor
  /// que viaja a la API / se usa en el link `tel:` sigue siendo el string
  /// completo; esto es solo para mostrar.
  static String formatTelefonoFijo(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith(telefonoFijoPrefix)
        ? trimmed.substring(telefonoFijoPrefix.length)
        : trimmed;
  }
}
