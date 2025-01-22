import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/widgets/blinking_border_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../theme/colors.dart';

class QuizOptionButton extends StatelessWidget {
  final String option;
  final int index;
  final int? selectedAnswer;
  final int? rightAnswer;
  final VoidCallback onPressed;
  final bool blink;
  final String gameId;

  const QuizOptionButton(
      {super.key,
      required this.option,
      required this.index,
      required this.selectedAnswer,
      required this.rightAnswer,
      required this.onPressed,
      required this.blink,
      required this.gameId});

  @override
  Widget build(BuildContext context) {
    final color = index == rightAnswer
        ? Colors.green
        : index == selectedAnswer
            ? rightAnswer != null && selectedAnswer != rightAnswer
                ? Colors.red
                : primaryColor
            : null;
    return GestureDetector(
      onTap: onPressed,
      child: BlinkingBorderContainer(
        blink: blink,
        alignment: Alignment.center,
        width: double.infinity,
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
              width: 0.25,
              color: index != selectedAnswer && index != rightAnswer
                  ? tint
                  : color ?? tint),
          color: color,
          borderRadius: BorderRadius.circular(10),
          // border: Border(
          //     right: BorderSide(color: Colors.white, width: 3),
          //     bottom: BorderSide(color: Colors.white, width: 3))
        ),
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              option.capitalize,
              style: GoogleFonts.baloo2(
                color: index != selectedAnswer && index != rightAnswer
                    ? tint
                    : Colors.white,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  String getOptionChar(int index) {
    if (index == 0) return "A";
    if (index == 1) return "B";
    if (index == 2) return "C";
    return "D";
  }
}
