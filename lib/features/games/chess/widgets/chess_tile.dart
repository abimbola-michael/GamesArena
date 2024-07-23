import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import '../../../../enums/emums.dart';
import '../../../../shared/widgets/svg_asset.dart';
import '../models/chess.dart';
import '../../../../shared/widgets/blinking_border_container.dart';

//Color tileColor = Colors.brown;
//Color tileColor = const Color(0xFF769655);
Color tileLightColor = const Color(0xFFF0D9B5);
Color tileDarkColor = const Color(0xFFB58863);

class ChessWidget extends StatelessWidget {
  final Chess chess;
  const ChessWidget({super.key, required this.chess});
  String getAsset() {
    final shape = chess.shape;
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

  String getAssetName() {
    final shape = chess.shape;
    String name = "";
    if (shape == ChessShape.bishop) {
      name = "chess_bishop_icon";
    } else if (shape == ChessShape.knight) {
      name = "chess_horse_knight_icon";
    } else if (shape == ChessShape.king) {
      name = "chess_king_icon";
    } else if (shape == ChessShape.pawn) {
      name = "chess_pawn_icon";
    } else if (shape == ChessShape.queen) {
      name = "chess_queen_icon";
    } else if (shape == ChessShape.rook) {
      name = "chess_rook_icon";
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final size = context.minSize / 16;
    return Hero(
      tag: chess.id,
      child: SvgAsset(
        name: getAssetName(),
        size: size,
        color: chess.player == 1 ? Colors.white : Colors.black,
      ),
      // child: Stack(
      //   //alignment: Alignment.center,
      //   children: [
      //     SvgAsset(
      //       name: getAssetName(),
      //       size: size,
      //       color: chess.player == 1 ? Colors.black : Colors.white,
      //     ),
      //     SvgAsset(
      //       name: getAssetName(),
      //       size: size - 4,
      //       color: chess.player == 1 ? Colors.white : Colors.black,
      //     ),
      //   ],
      // ),
    );
  }
}

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
      behavior: HitTestBehavior.opaque,
      child: BlinkingBorderContainer(
        blink: blink,
        height: size,
        width: size,
        alignment: Alignment.center,
        color: highLight
            ? Colors.purple
            : (x + y).isOdd
                ? tileDarkColor
                : tileLightColor,
        // ? tileColor
        // : tileColor.withOpacity(0.3),
        child: chessTile.chess == null
            ? null
            : RotatedBox(
                quarterTurns: chessTile.chess != null &&
                        chessTile.chess!.player == 0 &&
                        gameId == ""
                    ? 2
                    : 0,
                child: ChessWidget(chess: chessTile.chess!),
              ),
      ),
    );
  }
}
