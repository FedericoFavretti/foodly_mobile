/// País para el selector de código telefónico (equivalente a `phoneCodes.js` web).
class PhoneCountry {
  const PhoneCountry({
    required this.iso,
    required this.name,
    required this.code,
    required this.flag,
  });

  final String iso;
  final String name;

  /// Código de país con `+`, ej. `+598`.
  final String code;
  final String flag;
}

/// Resultado de separar un celular E.164 en país + número nacional.
class PhoneSplit {
  const PhoneSplit({required this.country, required this.number});

  final PhoneCountry country;
  final String number;
}

/// Lista curada de países para el campo de celular. Uruguay primero
/// (base de usuarios principal de la app).
abstract final class PhoneCodes {
  static const uruguay = PhoneCountry(
    iso: 'UY',
    name: 'Uruguay',
    code: '+598',
    flag: '🇺🇾',
  );

  static const all = <PhoneCountry>[
    uruguay,
    PhoneCountry(iso: 'AR', name: 'Argentina', code: '+54', flag: '🇦🇷'),
    PhoneCountry(iso: 'BR', name: 'Brasil', code: '+55', flag: '🇧🇷'),
    PhoneCountry(iso: 'CL', name: 'Chile', code: '+56', flag: '🇨🇱'),
    PhoneCountry(iso: 'PY', name: 'Paraguay', code: '+595', flag: '🇵🇾'),
    PhoneCountry(iso: 'BO', name: 'Bolivia', code: '+591', flag: '🇧🇴'),
    PhoneCountry(iso: 'PE', name: 'Perú', code: '+51', flag: '🇵🇪'),
    PhoneCountry(iso: 'EC', name: 'Ecuador', code: '+593', flag: '🇪🇨'),
    PhoneCountry(iso: 'CO', name: 'Colombia', code: '+57', flag: '🇨🇴'),
    PhoneCountry(iso: 'VE', name: 'Venezuela', code: '+58', flag: '🇻🇪'),
    PhoneCountry(iso: 'MX', name: 'México', code: '+52', flag: '🇲🇽'),
    PhoneCountry(iso: 'PA', name: 'Panamá', code: '+507', flag: '🇵🇦'),
    PhoneCountry(iso: 'CR', name: 'Costa Rica', code: '+506', flag: '🇨🇷'),
    PhoneCountry(iso: 'GT', name: 'Guatemala', code: '+502', flag: '🇬🇹'),
    PhoneCountry(iso: 'HN', name: 'Honduras', code: '+504', flag: '🇭🇳'),
    PhoneCountry(iso: 'SV', name: 'El Salvador', code: '+503', flag: '🇸🇻'),
    PhoneCountry(iso: 'NI', name: 'Nicaragua', code: '+505', flag: '🇳🇮'),
    PhoneCountry(iso: 'CU', name: 'Cuba', code: '+53', flag: '🇨🇺'),
    PhoneCountry(iso: 'US', name: 'Estados Unidos', code: '+1', flag: '🇺🇸'),
    PhoneCountry(iso: 'ES', name: 'España', code: '+34', flag: '🇪🇸'),
    PhoneCountry(iso: 'IT', name: 'Italia', code: '+39', flag: '🇮🇹'),
    PhoneCountry(iso: 'FR', name: 'Francia', code: '+33', flag: '🇫🇷'),
    PhoneCountry(iso: 'DE', name: 'Alemania', code: '+49', flag: '🇩🇪'),
    PhoneCountry(iso: 'GB', name: 'Reino Unido', code: '+44', flag: '🇬🇧'),
    PhoneCountry(iso: 'PT', name: 'Portugal', code: '+351', flag: '🇵🇹'),
  ];

  /// Separa un valor E.164 completo (ej. `+598991234567`) en país + número.
  ///
  /// Recorre los códigos ordenados por longitud descendente para no
  /// confundir prefijos cortos con largos (ej. `+1` vs `+598`). Si no
  /// matchea ningún código, o el valor viene vacío, asume Uruguay.
  static PhoneSplit split(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return const PhoneSplit(country: uruguay, number: '');
    }

    final byLongestCode = [...all]
      ..sort((a, b) => b.code.length.compareTo(a.code.length));
    for (final country in byLongestCode) {
      if (trimmed.startsWith(country.code)) {
        return PhoneSplit(
          country: country,
          number: trimmed.substring(country.code.length),
        );
      }
    }

    return PhoneSplit(country: uruguay, number: trimmed);
  }
}
