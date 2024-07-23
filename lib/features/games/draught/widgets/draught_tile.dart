import 'package:gamesarena/shared/widgets/blinking_border_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../shared/widgets/svg_asset.dart';
import '../models/draught.dart';

Color tileLightColor = const Color(0xFFF0D9B5);
Color tileDarkColor = const Color(0xFFB58863);
//Color tileColor = Colors.brown;

class DraughtTileWidget extends StatelessWidget {
  final DraughtTile draughtTile;
  final int x, y;
  final VoidCallback onPressed;
  final bool highLight;
  final double size;
  final String gameId;
  final bool blink;
  const DraughtTileWidget(
      {super.key,
      required this.x,
      required this.y,
      required this.draughtTile,
      required this.onPressed,
      required this.size,
      required this.gameId,
      required this.blink,
      this.highLight = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onPressed,
        child: BlinkingBorderContainer(
          blink: blink,
          width: size,
          height: size,
          alignment: Alignment.center,
          color: highLight
              ? Colors.purple
              : (x + y).isOdd
                  ? tileDarkColor
                  : tileLightColor,
          child: draughtTile.draught == null
              ? null
              : RotatedBox(
                  quarterTurns: draughtTile.draught != null &&
                          draughtTile.draught!.color == 0 &&
                          gameId == ""
                      ? 2
                      : 0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: size / 4,
                        backgroundColor: draughtTile.draught!.color == 1
                            ? const Color(0xffF6BE00)
                            : const Color(0xff722f37),
                      ),
                      if (draughtTile.draught!.king) ...[
                        SvgAsset(
                            name: "chess_king_icon",
                            size: size / 4,
                            color: Colors.white)
                        // SvgPicture.asset(
                        //   "assets/svgs/chess_king_icon.svg",
                        //   color: Colors.white,
                        //   width: size / 4,
                        //   height: size / 4,
                        // )
                      ]
                    ],
                  ),
                ),
        ));
  }
}
