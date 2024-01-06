import 'package:gamesarena/components/blinking_border_container.dart';
import 'package:gamesarena/models/games/xando.dart';
import 'package:flutter/material.dart';
import '../../utils/utils.dart';
import '../../enums/emums.dart';
import '../../styles/colors.dart';

class XandOTile extends StatelessWidget {
  final XandO xando;
  final VoidCallback onPressed;
  final bool blink;
  const XandOTile(
      {super.key,
      required this.xando,
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
          border: Border.all(width: 1.5, color: darkMode ? white : black),
          // border: Border(
          //     right: BorderSide(color: Colors.white, width: 3),
          //     bottom: BorderSide(color: Colors.white, width: 3))
        ),
        child: xando.char == XandOChar.empty
            ? null
            : Text(
                xando.char == XandOChar.x ? "X" : "O",
                style: TextStyle(
                    color: xando.char == XandOChar.x ? Colors.blue : Colors.red,
                    fontSize: 50),
              ),
      ),
    );
  }
}
