import 'package:gamesarena/shared/widgets/blinking_border_container.dart';
import 'package:gamesarena/enums/emums.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import '../../../../../theme/colors.dart';
import '../models/ludo.dart';
import '../../../../../shared/utils/utils.dart';

class LudoTileWidget extends StatelessWidget {
  final LudoTile? ludoTile;
  final LudoColor color;
  final List<LudoColor> colors;
  final int pos;
  final double size;
  final VoidCallback onPressed, onDoubleTap;
  final bool highLight;
  final bool blink;

  const LudoTileWidget(
      {super.key,
      required this.ludoTile,
      required this.color,
      required this.colors,
      required this.pos,
      required this.size,
      required this.onPressed,
      required this.onDoubleTap,
      required this.blink,
      this.highLight = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onPressed,
        onDoubleTap: onDoubleTap,
        child: BlinkingBorderContainer(
          blink: blink,
          height: size,
          width: size,
          blinkBorderColor:
              useColor(pos) && color == LudoColor.blue ? tint : gameHintColor,
          decoration: BoxDecoration(
            border: Border.all(color: tint, width: 1),
            color: ludoTile != null && highLight
                ? useColor(pos) && color == LudoColor.blue
                    ? tint
                    : gameHintColor
                : useColor(pos)
                    ? convertToColor(color)
                    : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (pos == 1) ...[
                Icon(
                  Icons.arrow_forward,
                  size: size / 2,
                  color: darkMode ? Colors.white : Colors.black,
                )
              ],
              if ((ludoTile?.ludos ?? []).isNotEmpty) ...[
                LudoDisc(
                  size: size.percentValue(60),
                  color:
                      convertToColor(colors[ludoTile!.ludos.first.houseIndex]),
                  ludosSize: ludoTile!.ludos.length,
                ),
              ],
            ],
          ),
        ));
  }

  bool useColor(int pos) {
    return (pos > 6 && pos < 12) || pos == 1;
  }

  Color convertToColor(LudoColor color) {
    if (color == LudoColor.blue) return Colors.blue;
    if (color == LudoColor.red) return Colors.red;
    if (color == LudoColor.yellow) return const Color(0xffF6BE00);
    if (color == LudoColor.green) return Colors.green;
    return const Color(0xffF6BE00);
  }
}

class LudoDisc extends StatelessWidget {
  final double size;
  final Color color;
  final int? ludosSize;
  const LudoDisc(
      {super.key, required this.size, required this.color, this.ludosSize});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(
              color: darkMode ? Colors.white : Colors.black, width: 1),
          shape: BoxShape.circle,
          color: color,
        ),
        alignment: Alignment.center,
        child: ludosSize != null && ludosSize! > 1
            ? Text(
                "$ludosSize",
                style: TextStyle(
                    fontSize: size.percentValue(70),
                    color: darkMode ? Colors.white : Colors.black),
                textAlign: TextAlign.center,
              )
            : null);
  }
}
