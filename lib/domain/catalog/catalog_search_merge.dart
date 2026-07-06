import '../../data/models/plato_model.dart';
import '../../data/models/promocion_model.dart';

/// Merge de platos y promociones — equivalente a `mapSearchResults` (web).
abstract final class CatalogSearchMerge {
  static List<PlatoModel> merge({
    required List<PlatoModel> platos,
    required List<PromocionModel> promociones,
  }) {
    final dishMap = <int, PlatoModel>{
      for (final plato in platos) plato.id: plato,
    };

    for (final promo in promociones) {
      final promoted = _promotedPlato(promo);
      if (promoted == null) continue;
      dishMap[promoted.id] = _mergeDishWithPromotion(
        dishMap[promoted.id],
        promoted,
      );
    }

    return dishMap.values.toList();
  }

  static PlatoModel? _promotedPlato(PromocionModel promo) {
    final embedded = promo.plato;
    if (embedded == null) return null;

    final basePrice = embedded.precio;
    final discountPercent = promo.descuento.round();
    final discountedPrice = _discountedPrice(basePrice, promo.descuento);

    return embedded.copyWith(
      precio: discountedPrice,
      precioOriginal: basePrice,
      tienePromocion: true,
      descuentoPercent: discountPercent,
      promocionId: promo.id,
      promocionTitulo: promo.descripcion,
    );
  }

  static PlatoModel _mergeDishWithPromotion(
    PlatoModel? base,
    PlatoModel promoted,
  ) {
    if (base == null) return promoted;

    final basePrice = base.precioOriginal ?? base.precio;
    final promotedPrice = promoted.precio;
    final currentPrice = base.precio;

    final shouldReplace = !base.tienePromocion ||
        promotedPrice < currentPrice ||
        (promotedPrice == currentPrice &&
            (promoted.descuentoPercent ?? 0) > (base.descuentoPercent ?? 0)) ||
        (base.promocionId == null && promoted.promocionId != null);

    if (!shouldReplace) return base;

    return base.copyWith(
      precio: promoted.precio,
      precioOriginal: basePrice > 0 ? basePrice : promoted.precioOriginal,
      tienePromocion: true,
      descuentoPercent: promoted.descuentoPercent,
      promocionId: promoted.promocionId,
      promocionTitulo: promoted.promocionTitulo ?? base.promocionTitulo,
    );
  }

  static double _discountedPrice(double basePrice, double discountPercent) {
    return (basePrice * (1 - discountPercent / 100)).roundToDouble();
  }
}
