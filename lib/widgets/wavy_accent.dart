import 'package:flutter/material.dart';

import '../theme/foodly_colors.dart';

class WavyAccent extends StatelessWidget {
  const WavyAccent({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 12),
      painter: _WavyPainter(),
    );
  }
}

class _WavyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FoodlyColors.amarillo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const waveWidth = 30.0;
    path.moveTo(0, size.height / 2);

    for (var x = 0.0; x <= size.width; x += waveWidth) {
      path.quadraticBezierTo(
        x + waveWidth / 4,
        0,
        x + waveWidth / 2,
        size.height / 2,
      );
      path.quadraticBezierTo(
        x + (waveWidth * 3) / 4,
        size.height,
        x + waveWidth,
        size.height / 2,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
