import 'package:gamesarena/theme/colors.dart';
import 'package:flutter/material.dart';

class Ball extends StatelessWidget {
  final double diameter;
  const Ball({super.key, this.diameter = 30});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: ballColor,
      radius: diameter / 2,
    );
  }
}
