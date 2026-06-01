class FoodItem {
  const FoodItem({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  final String title;
  final String description;
  final String imagePath;
}

const foodItems = [
  FoodItem(
    title: 'HAMBURGUESA',
    description:
        'Descubrí las mejores opciones en tu zona y pedí la hamburguesa que más te guste.',
    imagePath: 'assets/images/burger-card.png',
  ),
  FoodItem(
    title: 'PIZZA',
    description:
        'Pedí tu pizza favorita, con los ingredientes que elijas y al tamaño que prefieras.',
    imagePath: 'assets/images/pizza-card.png',
  ),
  FoodItem(
    title: 'PASTA',
    description:
        'Probá pastas hechas con dedicación y disfrutá sabores que te van a encantar.',
    imagePath: 'assets/images/pasta-card.png',
  ),
  FoodItem(
    title: 'SUSHI',
    description:
        'Disfrutá la frescura del mejor sushi, preparado con ingredientes de primera calidad.',
    imagePath: 'assets/images/sushi-card.png',
  ),
  FoodItem(
    title: 'HELADO',
    description:
        'Dale un toque dulce a tu día con helados cremosos y postres irresistibles.',
    imagePath: 'assets/images/ice-cream-card.png',
  ),
  FoodItem(
    title: 'MILANESA',
    description:
        'Pedí milanesas gigantes al horno o fritas, con papas y los agregados que quieras.',
    imagePath: 'assets/images/milanesa-card.png',
  ),
];
