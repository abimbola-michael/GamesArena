import 'package:flutter/material.dart';

class Bat extends StatelessWidget {
  final double width, height;
  final Color color;
  const Bat(
      {super.key,
      required this.height,
      required this.width,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
    );
  }
}
