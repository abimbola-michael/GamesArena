import 'package:gamesarena/enums/emums.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../../../../theme/colors.dart';
import '../models/match_line.dart';

List<Color> pathColors = [
  Colors.blue,
  Colors.yellow,
  Colors.red,
  Colors.indigo,
  Colors.orange,
  Colors.cyan,
  Colors.green,
  Colors.pink,
  Colors.deepPurple,
  Colors.teal,
  Colors.blueGrey,
  Colors.lime,
  Colors.purple,
  Colors.deepOrange,
  Colors.brown,
  Colors.blueGrey,
  Colors.lime,
  Colors.purple,
  Colors.deepOrange,
  Colors.brown,
];

class MatchLinesPainter extends CustomPainter {
  final BuildContext context;
  final int gridSize;
  final List<MatchLine> matchLines;
  final List<MatchLine> draggedMatchLines;
  final int player;

  MatchLinesPainter(
      {required this.matchLines,
      required this.draggedMatchLines,
      required this.context,
      required this.gridSize,
      required this.player});
  @override
  void paint(Canvas canvas, Size size) {
    void drawPaint(List<MatchLine> matchLines) {
      double size = context.minSize / gridSize;
      for (int i = 0; i < matchLines.length; i++) {
        final line = matchLines[i];
        //if (line.player != player) continue;
        // final color = line.player == 1 ? Colors.blue : Colors.red;
        //pathColors[line.wordIndex]
        // final color = line.wordIndex == -1
        //     ? primaryColor
        //     : line.player == 1
        //         ? Colors.blue
        //         : Colors.red;
        final color = line.wordIndex == -1
            ? primaryColor
            : [...Colors.primaries, ...Colors.accents][line.wordIndex];
        double lineHeight = size - 2;
        Paint paint = Paint()
          ..color = color.withOpacity(0.3)
          ..strokeWidth = lineHeight
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        Path path = Path();
        double centerPoint = (lineHeight / 2) + (size - lineHeight) / 2;

        path.moveTo(line.start.dx * size + centerPoint,
            line.start.dy * size + centerPoint);
        path.lineTo(
            line.end.dx * size + centerPoint, line.end.dy * size + centerPoint);
        canvas.drawPath(path, paint);
      }
    }

    drawPaint(matchLines);
    drawPaint(draggedMatchLines);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
