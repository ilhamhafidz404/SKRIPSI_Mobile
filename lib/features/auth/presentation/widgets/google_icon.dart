import 'package:flutter/material.dart';

class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w / 2, h / 2),
      Paint()..color = const Color(0xFFEA4335),
    );
    canvas.drawRect(
      Rect.fromLTWH(w / 2, 0, w / 2, h / 2),
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h / 2, w / 2, h / 2),
      Paint()..color = const Color(0xFFFBBC05),
    );
    canvas.drawRect(
      Rect.fromLTWH(w / 2, h / 2, w / 2, h / 2),
      Paint()..color = const Color(0xFF34A853),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
