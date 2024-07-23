import 'package:flutter/widgets.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../shared/utils/constants.dart';
import '../games/chess/pages/chess_game_page.dart';
import '../games/draught/pages/draught_game_page.dart';
import '../games/ludo/pages/ludo_game_page.dart';
import '../games/ludo/services.dart';
import '../games/whot/pages/whot_game_page.dart';
import '../games/whot/services.dart';
import '../games/word_puzzle/pages/word_puzzle_game_page.dart';
import '../games/xando/pages/xando_game_page.dart';
import '../user/models/user.dart';

void gotoGamePage(
    BuildContext context,
    String game,
    String gameId,
    String matchId,
    List<User?>? users,
    int playersSize,
    String? indices,
    int id,
    {Object? result}) async {
  // if (gameId != "" && indices == null) {
  //   if (game == "Ludo") {
  //     indices = await getLudoIndices(gameId);
  //   } else if (game == "Whot") {
  //     indices = await getWhotIndices(gameId);
  //   }
  // }
  // Widget? widget;
  int idCount = id++;
  // switch (game) {
  //   case batballGame:
  //     //widget =const BatballGamePage();
  //     break;
  //   case whotGame:
  //     widget = const WhotGamePage();
  //     break;
  //   case ludoGame:
  //     widget = const LudoGamePage();
  //     break;
  //   case draughtGame:
  //     widget = const DraughtGamePage();
  //     break;
  //   case chessGame:
  //     widget = const ChessGamePage();
  //     break;
  //   case xandoGame:
  //     widget = const XandOGamePage();
  //     break;
  //   case wordPuzzleGame:
  //     widget = const WordPuzzleGamePage();
  //     break;
  // }
  final args = {
    "matchId": matchId,
    "gameId": gameId,
    "users": users,
    "playersSize": users?.length ?? playersSize,
    "id": idCount,
    "indices": indices,
  };
  if (!context.mounted) return;
  context.pushNamedAndPop("/${game.replaceAll(" ", "").toLowerCase()}",
      args: args, result: result);
}
