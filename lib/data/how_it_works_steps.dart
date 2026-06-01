class HowItWorksStep {
  const HowItWorksStep({
    required this.step,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  final int step;
  final String title;
  final String description;
  final String imagePath;
}

const howItWorksSteps = [
  HowItWorksStep(
    step: 1,
    title: '1 Elegí tu comida',
    description:
        'Explorá restaurantes, bares y locales cerca tuyo. Compará menús, precios y tiempos de entrega.',
    imagePath: 'assets/images/step1.png',
  ),
  HowItWorksStep(
    step: 2,
    title: '2 Hacé tu pedido',
    description:
        'Agregá productos al carrito, elegí método de pago y confirmá. Nosotros nos encargamos del resto.',
    imagePath: 'assets/images/step2.png',
  ),
  HowItWorksStep(
    step: 3,
    title: '3 Recibí en tu casa',
    description:
        'Seguí tu pedido en tiempo real y recibilo en la puerta de tu casa, caliente y listo para disfrutar.',
    imagePath: 'assets/images/step3.png',
  ),
];
