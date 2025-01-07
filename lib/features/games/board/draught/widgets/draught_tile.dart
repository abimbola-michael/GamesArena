import 'package:gamesarena/shared/widgets/blinking_border_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../shared/widgets/svg_asset.dart';
import '../models/draught.dart';

Color tileLightColor = const Color(0xFFF0D9B5);
Color tileDarkColor = const Color(0xFFB58863);
//Color tileColor = Colors.brown;

class DraughtTileWidget extends StatelessWidget {
  final DraughtTile? draughtTile;
  final int x, y;
  final VoidCallback onPressed;
  final bool highLight;
  final double size;
  final String gameId;
  final bool blink;
  final int myPlayer;
  const DraughtTileWidget(
      {super.key,
      required this.x,
      required this.y,
      required this.draughtTile,
      required this.onPressed,
      required this.size,
      required this.gameId,
      required this.blink,
      this.highLight = false,
      required this.myPlayer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onPressed,
        child: BlinkingBorderContainer(
          blink: blink,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          color: draughtTile != null && highLight
              ? Colors.purple
              : (x + y).isOdd
                  ? tileDarkColor
                  : tileLightColor,
          child: draughtTile?.draught == null
              ? null
              : RotatedBox(
                  quarterTurns:
                      (gameId.isEmpty && draughtTile!.draught!.player == 0) ||
                              (gameId.isNotEmpty && myPlayer == 0)
                          ? 2
                          : 0,
                  child: DraughtWidget(
                      draught: draughtTile!.draught!, size: size / 2),
                ),
        ));
  }
}

class DraughtWidget extends StatelessWidget {
  final Draught draught;
  final double size;
  const DraughtWidget({super.key, required this.draught, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: draught.player == 1
              ? const Color(0xffF6BE00)
              : const Color(0xff722f37),
        ),
        if (draught.king) ...[
          SvgAsset(name: "chess_king_icon", size: size / 2, color: Colors.white)
        ]
      ],
    );
  }
}
