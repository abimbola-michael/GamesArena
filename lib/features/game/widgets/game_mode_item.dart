import 'package:flutter/material.dart';
import 'package:gamesarena/theme/colors.dart';

class GameModeItemWidget extends StatelessWidget {
  final String mode;
  final VoidCallback onPressed;
  const GameModeItemWidget(
      {super.key, required this.mode, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: lightestTint,
        ),
        child: Text(
          mode,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
