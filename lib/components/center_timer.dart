import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';

class CenterTimer extends StatelessWidget {
  final int time;
  const CenterTimer({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: context.isDarkMode ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(20)),
        child: Text(time.toDurationString(),
            style: TextStyle(
                color: context.isDarkMode ? Colors.black : Colors.white)),
      ),
    );
  }
}
