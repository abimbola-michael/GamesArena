import 'package:flutter/material.dart';

import '../../../../enums/emums.dart';

class WhotCardShapePaint extends CustomPainter {
  final WhotCardShape shape;
  const WhotCardShapePaint(this.shape);
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
