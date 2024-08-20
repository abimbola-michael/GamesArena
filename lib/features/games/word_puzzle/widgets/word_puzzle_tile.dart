import 'package:gamesarena/shared/widgets/blinking_border_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word_puzzle.dart';
import '../../../../theme/colors.dart';

class WordPuzzleTile extends StatelessWidget {
  final WordPuzzle wordPuzzle;
  final VoidCallback onPressed;
  final bool blink;
  final bool highLight;
  const WordPuzzleTile(
      {super.key,
      required this.wordPuzzle,
      required this.onPressed,
      required this.blink,
      required this.highLight});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: BlinkingBorderContainer(
        blink: blink,
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // border: Border.all(width: 0.5, color: tint),
          color: highLight ? Colors.purple : null,
          // border: Border(
          //     right: BorderSide(color: Colors.white, width: 3),
          //     bottom: BorderSide(color: Colors.white, width: 3))
        ),
        child: Text(
          wordPuzzle.char,
          style: GoogleFonts.baloo2(
            // color: xando.char == XandOChar.x ? Colors.blue : Colors.red,
            fontSize: 16,
            //fontWeight: FontWeight.bold,
          ),
          // style: const TextStyle(
          //   // color: xando.char == XandOChar.x ? Colors.blue : Colors.red,
          //   fontSize: 16,
          //   //fontWeight: FontWeight.bold,
          // ),
        ),
      ),
    );
  }
}
