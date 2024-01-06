import 'package:gamesarena/enums/emums.dart';
import 'package:flutter/material.dart';

class XandOLinePainter extends CustomPainter {
  final XandOWinDirection direction;
  final int index;
  final Color color;
  final double thickness;
  XandOLinePainter(
      {required this.direction,
      required this.index,
      required this.color,
      required this.thickness});
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;
    canvas.drawPath(getPath(size), paint);
  }

  Path getPath(Size size) {
    final width = size.width;
    final height = size.height;
    final offset = width / 6;
    Path path = Path();
    if (direction == XandOWinDirection.vertical) {
      final x = index == 0
          ? offset
          : index == 1
              ? width / 2
              : width - offset;
      return Path()
        ..moveTo(x, 0)
        ..lineTo(x, height);
    } else if (direction == XandOWinDirection.horizontal) {
      final y = index == 0
          ? offset
          : index == 1
              ? height / 2
              : height - offset;
      return Path()
        ..moveTo(0, y)
        ..lineTo(width, y);
    } else if (direction == XandOWinDirection.lowerDiagonal) {
      return Path()
        ..moveTo(0, height)
        ..lineTo(width, 0);
    } else if (direction == XandOWinDirection.upperDiagonal) {
      return Path()
        ..moveTo(width, height)
        ..lineTo(0, 0);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
