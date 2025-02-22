import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:gamesarena/theme/colors.dart';

import '../../../../../shared/widgets/blinking_border_container.dart';
import '../../../../../shared/widgets/circle_progress_bar.dart';

class RollDiceButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int playerTime;
  final bool blink;
  const RollDiceButton(
      {super.key,
      required this.onPressed,
      required this.blink,
      required this.playerTime});

  @override
  Widget build(BuildContext context) {
    // final playerTime = ref.read(playerTimerProvider);
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: LayoutBuilder(builder: (context, constaints) {
          final height = constaints.maxHeight;
          final width = constaints.maxWidth;
          final minimum = min(height, width);

          return BlinkingBorderContainer(
            blink: blink,
            width: minimum < 70 ? minimum - 4 : 70,
            height: minimum < 70 ? minimum - 4 : 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.transparent,
                    //color: darkMode ? Colors.white : Colors.black,
                    width: 3),
                color: lightestTint,
                borderRadius: BorderRadius.circular(35)),
            child: TweenAnimationBuilder(
                tween: Tween<double>(
                    begin: (30 - playerTime).toDouble(),
                    end: (30 - playerTime + 1).toDouble()),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return CircleProgressBar(
                      progress: value,
                      total: 30,
                      width: 70,
                      height: 70,
                      progressColor: primaryColor,
                      strokeColor: lighterTint,
                      backgroundColor: Colors.transparent,
                      strokeWidth: 4,
                      child: Image.asset(
                        "assets/images/die.png",
                        width: 35,
                        height: 35,
                      ));
                }),
          );
        }));
  }
}
