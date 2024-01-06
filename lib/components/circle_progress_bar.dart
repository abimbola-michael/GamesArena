// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math';

import 'package:flutter/material.dart';

class CircleProgressBar extends StatelessWidget {
  final double progress, total;
  final double width, height, strokeWidth;
  final Color progressColor, strokeColor, backgroundColor;
  final Widget? child;

  const CircleProgressBar(
      {super.key,
      required this.total,
      required this.strokeWidth,
      required this.progress,
      required this.width,
      required this.height,
      required this.progressColor,
      required this.strokeColor,
      required this.backgroundColor,
      this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: CircularProgressBarPainter(
                progress: progress / total,
                strokeWidth: strokeWidth,
                progressColor: progressColor,
                strokeColor: strokeColor,
                backgroundColor: backgroundColor),
          ),
          child ?? const SizedBox(),
        ],
      ),
    );
  }
}

class CircularProgressBarPainter extends CustomPainter {
  final double progress, strokeWidth;
  final Color progressColor, strokeColor, backgroundColor;

  const CircularProgressBarPainter({
    required this.strokeWidth,
    required this.progressColor,
    required this.strokeColor,
    required this.backgroundColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2 - strokeWidth / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    //print("progress: $progress");
    final Paint paint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Draw the background circle
    canvas.drawCircle(center, radius, paint..color = strokeColor);

    // Draw the progress arc
    double sweepAngle = 360 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      radians(-90), // Start angle at 12 o'clock position
      radians(sweepAngle),
      false,
      paint..color = progressColor,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  double radians(double degrees) {
    return degrees * (pi / 180.0);
  }
}
