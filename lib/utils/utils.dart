import 'package:gamesarena/blocs/firebase_service.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';

import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/main.dart';

import '../../enums/emums.dart';
import '../../models/games/ludo.dart';
import '../../models/games/whot.dart';
import '../models/playing.dart';
import '../models/user.dart';
import '../pages/games/batball_game_page.dart';
import '../pages/games/chess_game_page.dart';
import '../pages/games/draught_game_page.dart';
import '../pages/games/ludo_game_page.dart';
import '../pages/games/whot_game_page.dart';
import '../pages/games/xando_game_page.dart';

// bool get darkMode =>
//     SchedulerBinding.instance.window.platformBrightness == Brightness.dark;

bool get darkMode => themeValue == 1;
List<String> capsalphabets = [
  "A",
  "B",
  "C",
  "D",
  "E"
      "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "W",
  "X",
  "Y",
  "Z"
];
List<String> alphabets = [
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z",
];
List<String> numbers = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
List<String> alphanumeric = [...alphabets, ...capsalphabets, ...numbers];
const String CHANNEL_ID = "com.hms.gamesarena";
const String CHANNEL_NAME = "Games Arena";
const String CHANNEL_DESC = "This is a channel for Games Arena games";

const String batballGame = "Bat Ball";
const String xandoGame = "X and O";
const String whotGame = "Whot";
const String ludoGame = "Ludo";
const String draughtGame = "Draught";
const String chessGame = "Chess";

const String playedBatballGame = "playedBatball";
const String playedXandoGame = "playedXando";
const String playedWhotGame = "playedWhot";
const String playedLudoGame = "playedLudo";
const String playedDraughtGame = "playedDraught";
const String playedChessGame = "playedChess";

List<String> games = [
  "Chess",
  "Draught",
  "Whot",
  "Ludo",
  "X and O",
  //"Bat Ball",
  //"Ayo",
  //"Snooker"
  //"Jackpot",
  //"Scrabble"
];

List<String> modes = [
  "Online",
  "Offline",
];
List<LudoColor> ludoColors = [
  LudoColor.yellow,
  LudoColor.green,
  LudoColor.red,
  LudoColor.blue
];
List<WhotCardShape> whotCardShapes = [
  WhotCardShape.circle,
  WhotCardShape.triangle,
  WhotCardShape.cross,
  WhotCardShape.square,
  WhotCardShape.star,
  WhotCardShape.whot
];

List<Whot> getWhots() {
  List<Whot> whots = [
    ...List.generate(14, (index) => Whot("", index + 1, 0))
        .where((value) => value.number != 6 && value.number != 9),
    ...List.generate(14, (index) => Whot("", index + 1, 1))
        .where((value) => value.number != 6 && value.number != 9),
    ...List.generate(14, (index) => Whot("", index + 1, 2)).where((value) =>
        value.number != 6 &&
        value.number != 9 &&
        value.number != 4 &&
        value.number != 8 &&
        value.number != 12),
    ...List.generate(14, (index) => Whot("", index + 1, 3)).where((value) =>
        value.number != 6 &&
        value.number != 9 &&
        value.number != 4 &&
        value.number != 8 &&
        value.number != 12),
    ...List.generate(8, (index) => Whot("", index + 1, 4))
        .where((value) => value.number != 6),
    ...List.generate(5, (index) => Whot("", 20, 5)),
  ];
  for (int i = 0; i < whots.length; i++) {
    whots[i].id = "$i";
  }
  return whots;
}

List<String> getRandomIndex(int size) {
  List<String> indices = List.generate(size, (index) => "$index");
  for (int i = 0; i < 10; i++) {
    indices.shuffle();
  }
  return indices;
}

List<Ludo> getLudos() {
  return List.generate(16, (index) {
    final i = index ~/ 4;
    return Ludo("$index", -1, -1, -1, i, i);
  });
}

List<int> getPlayersToRemove(List<User?> users, List<Playing> playing) {
  List<int> indices = [];
  for (int i = 0; i < users.length; i++) {
    final user = users[i];
    final index = playing.indexWhere((element) => element.id == user?.user_id);
    if (index == -1) {
      indices.add(i);
    }
  }
  return indices;
}

String getWinnerMessage(List<int> playersScores, List<User?>? users) {
  String message = "";
  Map<int, List<int>> resultMap = {};
  for (int i = 0; i < playersScores.length; i++) {
    final score = playersScores[i];
    if (resultMap[score] != null) {
      resultMap[score]!.add(i);
    } else {
      resultMap[score] = [i];
    }
  }
  final scores = resultMap.keys.toList();
  final highestScore = scores.sortedList((value) => value, false).last;
  final players = resultMap[highestScore]!;
  if (players.length > 1) {
    if (scores.length == 1) {
      message = "It's a draw";
    } else {
      String tiePlayers = "";
      if (users != null) {
        tiePlayers = users.toStringWithCommaandAnd((user) => user!.username);
      } else {
        tiePlayers = resultMap[highestScore]!
            .toStringWithCommaandAnd((value) => "${value + 1}", "Player ");
      }
      message = "It's a tie between $tiePlayers";
    }
  } else {
    final player = players.first;
    message = users != null
        ? "${users[player]?.username} Won"
        : "Player ${player + 1} Won";
  }

  return message;
}

String getActionMessage(List<Playing> prevPlaying, List<Playing> newPlaying,
    List<User> users, String game) {
  prevPlaying.sortList((value) => value.order, false);
  newPlaying.sortList((value) => value.order, false);
  List<Playing> playing = newPlaying, toPlaying = prevPlaying;
  String action = "";
  if (newPlaying.length > prevPlaying.length) {
    action = "joined";
    playing = newPlaying;
    toPlaying = prevPlaying;
  } else if (newPlaying.length < prevPlaying.length) {
    action = "left";
    playing = prevPlaying;
    toPlaying = newPlaying;
  }
  for (int i = 0; i < playing.length; i++) {
    final value = playing[i];
    final toValue = toPlaying[i];
    final username =
        users.firstWhere((element) => element.user_id == value.id).username;
    if (value.id != toValue.id) {
      return "$username $action";
    }
    if (value.action != toValue.action) {
      return "$username ${getActionString(value.action)}";
    }
  }
  return "";
}

void gotoOnlineGamePage(BuildContext context, String game, String gameId,
    String matchId, List<User?> users, String? indices, int id) async {
  FirebaseService fs = FirebaseService();
  if (indices == null) {
    if (game == "Ludo") {
      indices = await fs.getLudoIndices(gameId);
    } else if (game == "Whot") {
      indices = await fs.getWhotIndices(gameId);
    }
  }
  Widget widget = const BatballGamePage();
  int idCount = id++;
  if (game == "Bat Ball") {
    widget = BatballGamePage(
      matchId: matchId,
      gameId: gameId,
      users: users,
      id: idCount,
    );
  } else if (game == "Whot") {
    widget = WhotGamePage(
      matchId: matchId,
      gameId: gameId,
      users: users,
      indices: indices,
      id: idCount,
    );
  } else if (game == "Ludo") {
    widget = LudoGamePage(
      matchId: matchId,
      gameId: gameId,
      users: users,
      indices: indices,
      id: idCount,
    );
  } else if (game == "Draught") {
    widget = DraughtGamePage(
      matchId: matchId,
      gameId: gameId,
      users: users,
      id: idCount,
    );
  } else if (game == "Chess") {
    widget = ChessGamePage(
      matchId: matchId,
      gameId: gameId,
      users: users,
      id: idCount,
    );
  } else if (game == "X and O") {
    widget = XandOGamePage(
      matchId: matchId,
      gameId: gameId,
      users: users,
      id: idCount,
    );
  }
  Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: ((context) => widget)));
}

void gotoOfflineGamePage(
    BuildContext context, String game, int playersSize, int id) {
  Widget widget = const BatballGamePage();
  int idCount = id++;

  if (game == "Bat Ball") {
    widget = BatballGamePage(
      id: idCount,
    );
  } else if (game == "Whot") {
    widget = WhotGamePage(
      playersSize: playersSize,
      id: idCount,
    );
  } else if (game == "Ludo") {
    widget = LudoGamePage(
      playersSize: playersSize,
      id: idCount,
    );
  } else if (game == "Draught") {
    widget = DraughtGamePage(
      id: idCount,
    );
  } else if (game == "Chess") {
    widget = ChessGamePage(
      id: idCount,
    );
  } else if (game == "X and O") {
    widget = XandOGamePage(
      id: idCount,
    );
  }
  Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: ((context) => widget)));
}

String getAction(List<Playing> playing) {
  String action = "";
  for (int i = 0; i < playing.length; i++) {
    final player = playing[i];
    if (action == "") {
      action = player.action;
    } else {
      if (action != player.action) {
        return "pause";
      }
    }
  }
  return action;
}

String getChangedGame(List<Playing> playing) {
  String game = "";
  for (int i = 0; i < playing.length; i++) {
    final player = playing[i];
    if (game == "") {
      game = player.game;
    } else {
      if (game != player.game) {
        return "";
      }
    }
  }
  return game;
}

String getActionString(String action) {
  return action == "start"
      ? "started"
      : action == "restart"
          ? "restarted"
          : action == "pause"
              ? "paused"
              : action;
}

void updateAction(
    BuildContext context,
    FirebaseService fs,
    List<Playing> playing,
    List<User?> users,
    String gameId,
    String matchId,
    String myId,
    String action,
    String game,
    bool started,
    int id,
    int duration) async {
  final myPlaying = playing.firstWhere((element) => element.id == myId);
  final myAction = myPlaying.action;
  if (myAction != action) {
    if (action == "restart") {
      await fs.restartGame(game, gameId, matchId, playing, id, duration);
    } else if (action == "start") {
      await fs.startGame(game, gameId, matchId, playing, id, started);
    }
  }
  final othersPlaying = playing.where((element) => element.id != myId).toList();
  final othersWithDiffAction = othersPlaying
      .where((element) => element.id != myId && element.action != myAction)
      .toList();
  if (othersWithDiffAction.isNotEmpty) {
    List<User> waitingUsers = [];
    for (int i = 0; i < othersWithDiffAction.length; i++) {
      final player = othersWithDiffAction[i];
      final user = users.firstWhere(
          (element) => element != null && element.user_id == player.id);
      if (user != null) {
        waitingUsers.add(user);
      }
    }
    Fluttertoast.showToast(
        msg:
            "Waiting for ${waitingUsers.toStringWithCommaandAnd((user) => user.username)} to also $action");
  }
}

String getUsername(List<User?> users, String userId) =>
    users
        .firstWhere((element) => element != null && element.user_id == userId)
        ?.username ??
    "";
List<int> convertToGrid(int pos, int gridSize) {
  return [pos % gridSize, pos ~/ gridSize];
}

int convertToPosition(List<int> grids, int gridSize) {
  return grids[0] + (grids[1] * gridSize);
}

int nextIndex(int playersSize, int index) {
  return index == playersSize - 1 ? 0 : index + 1;
}

int prevIndex(int playersSize, int index) {
  return index == 0 ? playersSize - 1 : index - 1;
}

const int maxHintTime = 5;
const int maxGameTime = 20 * 60;
const int maxPlayerTime = 30;
const int maxChessDraughtTime = 10 * 60;
const int maxAdsTime = 60 * 5;
final adUnitId = Platform.isAndroid
    ? 'ca-app-pub-3940256099942544/1033173712'
    : 'ca-app-pub-3940256099942544/4411468910';
