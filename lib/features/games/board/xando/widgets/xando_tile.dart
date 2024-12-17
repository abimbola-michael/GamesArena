import 'package:gamesarena/shared/widgets/blinking_border_container.dart';
import 'package:gamesarena/features/games/board/xando/models/xando.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../enums/emums.dart';
import '../../../../../theme/colors.dart';

class XandOTileWidget extends StatelessWidget {
  final XandOTile xandOTile;
  final VoidCallback onPressed;
  final bool blink;
  const XandOTileWidget(
      {super.key,
      required this.xandOTile,
      required this.onPressed,
      required this.blink});

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
          border: Border.all(width: 1.5, color: tint),
          // border: Border(
          //     right: BorderSide(color: Colors.white, width: 3),
          //     bottom: BorderSide(color: Colors.white, width: 3))
        ),
        child: xandOTile.char == null
            ? null
            : Text(
                xandOTile.char == XandOChar.x ? "X" : "O",
                style: GoogleFonts.rubikMonoOne(
                    color: xandOTile.char == XandOChar.x
                        ? Colors.blue
                        : Colors.red,
                    fontSize: 70),
                // style: TextStyle(
                //     color: xando.char == XandOChar.x ? Colors.blue : Colors.red,
                //     fontSize: 50),
              ),
      ),
    );
  }
}
