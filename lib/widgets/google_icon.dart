import 'package:flutter/material.dart';

class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5,
      3.5,
      true,
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.2,
      2.2,
      true,
      Paint()..color = const Color(0xFF34A853),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.2,
      2.0,
      true,
      Paint()..color = const Color(0xFFFBBC05),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -2.4,
      2.0,
      true,
      Paint()..color = const Color(0xFFEA4335),
    );

    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
