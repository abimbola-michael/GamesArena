import 'package:flutter/material.dart';

import '../utils/utils.dart';

class BoardCenter extends StatelessWidget {
  final int diameter;
  const BoardCenter({super.key, required this.diameter});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: diameter.toDouble(),
      width: diameter.toDouble(),
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
              width: 5, color: darkMode ? Colors.white : Colors.black)),
    );
  }
}
