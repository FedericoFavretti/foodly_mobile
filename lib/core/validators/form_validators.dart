abstract final class FormValidators {
  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  static final _ciRegex = RegExp(r'^\d{7,8}$');
  static final _passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$');

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Ingresá tu correo electrónico.';
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'El correo electrónico no tiene un formato válido.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresá tu contraseña.';
    if (!_passwordRegex.hasMatch(value)) {
      return 'La contraseña debe tener al menos 8 caracteres, una letra mayúscula y un número.';
    }
    return null;
  }

  static String? requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Ingresá $label.';
    return null;
  }

  static String? cedula(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (!_ciRegex.hasMatch(digits)) {
      return 'El documento debe ser una cédula uruguaya válida (7 u 8 dígitos).';
    }
    return null;
  }

  static String? confirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'Confirmá tu contraseña.';
    }
    if (password != confirm) {
      return 'Las contraseñas ingresadas no coinciden. Por favor, verifique e inténtelo de nuevo.';
    }
    return null;
  }
}
