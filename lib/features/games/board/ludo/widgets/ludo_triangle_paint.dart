import 'package:flutter/material.dart';

class LudoTrianglePainter extends CustomPainter {
  final Color color;
  LudoTrianglePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(getPath(size), paint);
  }

  Path getPath(Size size) {
    final width = size.width;
    final height = size.height;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(width, height / 2)
      ..lineTo(0, height)
      ..lineTo(0, 0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
