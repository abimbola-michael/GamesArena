import 'package:gamesarena/enums/emums.dart';
import 'package:flutter/material.dart';

class ShapesPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final WhotCardShape cardShape;
  ShapesPainter(
      {required this.color, required this.thickness, required this.cardShape});
  @override
  void paint(Canvas canvas, Size size) {
    drawShape(canvas, size);
  }

  void drawShape(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final width = size.width;
    final height = size.height;
    if (cardShape == WhotCardShape.circle) {
      canvas.drawCircle(Offset(width / 2, width / 2), width / 2, paint);
    } else if (cardShape == WhotCardShape.square) {
      canvas.drawRect(Rect.fromLTRB(0, 0, width, height), paint);
    } else if (cardShape == WhotCardShape.triangle) {
      Path path = Path()
        ..moveTo(width / 2, 0)
        ..lineTo(0, height)
        ..lineTo(width, height)
        ..lineTo(width / 2, 0);
      canvas.drawPath(path, paint);
    } else if (cardShape == WhotCardShape.cross) {
      paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width / 2;
      canvas.drawLine(
        Offset(0, height / 2),
        Offset(width, height / 2),
        paint,
      );
      canvas.drawLine(
        Offset(width / 2, 0),
        Offset(width / 2, height),
        paint,
      );
    } else if (cardShape == WhotCardShape.star) {
      Path path = Path();
      double length = width / 5;
      double x = width / 2;
      double y = 0;
      Direction vDir = Direction.down;
      Direction hDir = Direction.left;
      path.moveTo(x, y);
      for (int i = 0; i < 10; i++) {
        if (x <= 0) {
          hDir = Direction.right;
        }
        if (x >= width) {
          hDir = Direction.left;
        }
        x = hDir == Direction.left ? x - length : x + length;

        if (y <= 0) {
          vDir = Direction.down;
        }
        if (y >= height) {
          vDir = Direction.up;
        }
        y = vDir == Direction.up ? y - length : y + length;

        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  List<int> convertToGrid(int pos, int gridSize) {
    return [pos % gridSize, pos ~/ gridSize];
  }

  int convertToPosition(List<int> grids, int gridSize) {
    return grids[0] + (grids[1] * gridSize);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
