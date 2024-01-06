import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../enums/emums.dart';
import '../../models/games/chess.dart';
import '../blinking_border_container.dart';

//Color tileColor = const Color(0xFF056608);
Color tileColor = const Color(0xFF769655);

class ChessTileWidget extends StatelessWidget {
  final ChessTile chessTile;
  final int x, y;
  final VoidCallback onPressed;
  final bool highLight;
  final double size;
  final String gameId;
  final bool blink;
  const ChessTileWidget(
      {super.key,
      required this.x,
      required this.y,
      required this.chessTile,
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
          height: size,
          width: size,
          alignment: Alignment.center,
          color: highLight
              ? Colors.purple
              : (x + y).isOdd
                  ? tileColor
                  : tileColor.withOpacity(0.3),
          child: chessTile.chess == null
              ? null
              : RotatedBox(
                  quarterTurns:
                      chessTile.chess != null && chessTile.chess!.player == 0
                          ? 2
                          : 0,
                  child: SvgPicture.asset(
                    getAsset(),
                    width: size / 2,
                    height: size / 2,
                    color: chessTile.chess!.color == 1
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
        ));
  }

  String getAsset() {
    final shape = chessTile.chess!.shape;
    String asset = "";
    if (shape == ChessShape.bishop) {
      asset = "assets/svgs/chess_bishop_icon.svg";
    } else if (shape == ChessShape.knight) {
      asset = "assets/svgs/chess_horse_knight_icon.svg";
    } else if (shape == ChessShape.king) {
      asset = "assets/svgs/chess_king_icon.svg";
    } else if (shape == ChessShape.pawn) {
      asset = "assets/svgs/chess_pawn_icon.svg";
    } else if (shape == ChessShape.queen) {
      asset = "assets/svgs/chess_queen_icon.svg";
    } else if (shape == ChessShape.rook) {
      asset = "assets/svgs/chess_rook_icon.svg";
    }
    return asset;
  }
}
