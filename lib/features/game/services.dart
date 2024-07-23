import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:gamesarena/core/firebase/firestore_methods.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/constants.dart';

import '../../../shared/utils/utils.dart';
import '../../shared/models/event_change.dart';
import '../../shared/services.dart';
import '../game/models/player.dart';
import '../games/batball/services.dart';
import '../games/chess/services.dart';
import '../games/draught/services.dart';
import '../games/ludo/services.dart';
import '../games/whot/services.dart';
import '../games/word_puzzle/services.dart';
import '../games/xando/services.dart';
import '../records/services.dart';
import 'models/game.dart';
import 'models/game_list.dart';
import 'models/game_request.dart';
import 'models/playing.dart';
import 'models/match.dart';

FirestoreMethods fm = FirestoreMethods();

Future<List<Player>> readPlayers() async {
  return fm.getValues((map) => Player.fromMap(map), ["users", myId, "players"]);
}

Future<List<Player>> readGroupPlayers(String groupId) async {
  return fm
      .getValues((map) => Player.fromMap(map), ["groups", groupId, "players"]);
}

Future<Game?> getGameFromPlayers(String playersString) async {
  List<String> playerIds =
      playersString.contains(",") ? playersString.split(",") : [playersString];
  if (!playerIds.contains(myId)) {
    playerIds.insert(0, myId);
  }
  String gameId = getGameId(playerIds);
  return fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
}

Future<GameRequest?> createGame(
    String gameName, String groupId, List<String> playerIds) async {
  String time = DateTime.now().millisecondsSinceEpoch.toString();
  if (playerIds.length < 2) {
    Fluttertoast.showToast(msg: "Can't create game for only one user");
    return null;
  }

  playerIds.sort(((a, b) => a.compareTo(b)));
  String gameId = getGameId(playerIds);
  final game = await fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
  if (game == null) {
    String players = playerIds.join(",");
    Game game = Game(players: players, game_id: gameId, time: time);
    await fm.setValue(["games", gameId], value: game.toMap());
  }
  List<int> orders = List.generate(playerIds.length, (index) => index + 1);
  orders.shuffle();
  List<Playing> playingList = [];
  for (int i = 0; i < playerIds.length; i++) {
    String playerId = playerIds[i];
    final order = orders[i];
    final playing = Playing(
      id: playerId,
      action: "pause",
      game: gameName,
      accept: playerId == myId,
      order: order,
    );
    playingList.add(playing);
  }
  playingList.sortList((value) => value.order, false);
  String matchId = fm.getId(["games", gameId, "matches"]);
  final match = Match(
    match_id: matchId,
    creator_id: myId,
    time_created: time,
    player1: playingList.first.id,
    player2: playingList.second?.id,
    player3: playingList.third?.id,
    player4: playingList.fourth?.id,
  );
  await fm.setValue(["games", gameId, "matches", matchId],
      value: match.toMap().removeNull());
  //await createGameDetails(gameName, gameId);
  // if (gameName == "Ludo" || gameName == "Whot") {
  // }

  for (int i = 0; i < playingList.length; i++) {
    final playing = playingList[i];
    String playerId = playing.id;
    await fm.setValue(["games", gameId, "playing", playerId],
        value: playing.toMap());
  }

  GameRequest request = GameRequest(
    game_id: gameId,
    match_id: matchId,
    game: gameName,
    creator_id: myId,
  );
  for (int i = 0; i < playingList.length; i++) {
    final playing = playingList[i];
    String playerId = playing.id;
    await fm.setValue(["users", playerId, "game"], value: request.toMap());
    await fm.setValue(["users", playerId, "gamelist", gameId],
        value: GameList(game_id: gameId, time: time).toMap());
    if (playerId != myId) {
      if ((await fm.getValue((map) => Player.fromMap(map),
              ["users", myId, "players", playerId])) ==
          null) {
        await fm.setValue(["users", myId, "players", playerId],
            value: Player(id: playerId, time: time).toMap());
      }
      if ((await fm.getValue((map) => Player.fromMap(map),
              ["users", playerId, "players", myId])) ==
          null) {
        await fm.setValue(["users", playerId, "players", myId],
            value: Player(id: myId, time: time).toMap());
      }
    }
  }
  await sendPushNotificationToPlayers(gameName, playerIds);
  return request;
}

// Future createGameDetails(String game, String gameId) async {
//   switch (game) {
//     case chessGame:
//       return setChessDetails(gameId);
//     case draughtGame:
//       return setDraughtDetails(gameId);
//     case batballGame:
//       return setBatBallDetails(gameId);
//     case xandoGame:
//       return setXandODetails(gameId);
//     case whotGame:
//       return setWhotDetails(gameId);
//     case ludoGame:
//       return setLudoDetails(gameId);
//     case wordPuzzleGame:
//       return setWordPuzzleDetails(gameId);
//   }
// }

Future cancelGame(String gameId, String matchId, List<Playing> playing) async {
  await fm.removeValue(["games", gameId, "playing"]);
  await fm.removeValue(["games", gameId, "details"]);
  for (var player in playing) {
    await fm.removeValue(["users", player.id, "game"]);
  }
}

Future joinGame(String gameId, String matchId) async {
  await fm.updateValue(["games", gameId, "playing", myId],
      value: {"accept": true, "time": timeNow});
}

Future leaveGame(String gameId, String matchId, List<Playing> playing,
    bool started, int id, int duration) async {
  if (started) {
    if (playing.length == 2) {
      await fm.updateValue(["games", gameId, "matches", matchId],
          value: {"time_end": timeNow});
      await fm.removeValue(["games", gameId, "details"]);
    }
    if (playing.length > 2) {
      await pauseGame(gameId, matchId, playing, id, duration);
    }
  }
  await fm.removeValue(["users", myId, "game"]);
  await fm.removeValue(["games", gameId, "playing", myId]);
}

Future startGame(String game, String gameId, String matchId,
    List<Playing> playing, int id, bool started) async {
  await fm.updateValue(["games", gameId, "playing", myId],
      value: {"action": "start", "game": game});
  if (!started) {
    final unstartedPlayers =
        playing.where((element) => element.action != "start");
    if (unstartedPlayers.length == 1) {
      await addMatchRecord(game, gameId, matchId, playing, id);
      if (id == 0) {
        await fm.updateValue(["games", gameId, "matches", matchId],
            value: {"time_start": timeNow});
      }
    }
  }
}

Future restartGame(String game, String gameId, String matchId,
    List<Playing> playing, int id, int duration) async {
  await fm.updateValue(["games", gameId, "playing", myId],
      value: {"action": "restart", "game": game});

  final unrestartedPlayers =
      playing.where((element) => element.action != "restart");
  if (unrestartedPlayers.length == 1) {
    await fm.updateValue(
        ["games", gameId, "matches", matchId, "records", "$id"],
        value: {"time_end": timeNow, "duration": duration});

    await addMatchRecord(game, gameId, matchId, playing, id + 1);
  }
}

Future changeGame(String game, String gameId, String matchId,
    List<Playing> playing, int id, int duration) async {
  final gamePlayers = playing.where((element) => element.game != game);
  if (gamePlayers.length == 1) {
    await fm.updateValue(
        ["games", gameId, "matches", matchId, "records", "$id"],
        value: {"time_end": timeNow, "duration": duration});
    await fm.removeValue(["games", gameId, "details"]);
    //await createGameDetails(game, gameId);
  }
  await fm.updateValue(["games", gameId, "playing", myId],
      value: {"game": game, "action": "pause"});
}

Future pauseGame(String gameId, String matchId, List<Playing> playing, int id,
    int duration) async {
  if (playing.isNotEmpty) {
    for (var player in playing) {
      if (player.action != "pause") {
        await fm.updateValue(["games", gameId, "playing", player.id],
            value: {"action": "pause"});
        await fm.updateValue(
            ["games", gameId, "matches", matchId, "records", "$id"],
            value: {"duration": duration});
      }
    }
  }
}

Future removeGameRequest() async {
  await fm.removeValue(["users", myId, "game"]);
}

Future removeGameDetails(String gameId) async {
  return fm.removeValue(["games", gameId, "details"]);
}

Stream<GameRequest?> getGameRequest() async* {
  yield* fm.getValueStream(
      (map) => GameRequest.fromMap(map), ["users", myId, "game"]);
}

Future<GameRequest?> checkGameRequest(String id) async {
  return fm.getValue((map) => GameRequest.fromMap(map), ["users", id, "game"]);
}

Future<List<Playing>> getPlaying(String gameId) async {
  return fm
      .getValues((map) => Playing.fromMap(map), ["games", gameId, "playing"]);
}

Stream<List<Playing>> readPlaying(String gameId) async* {
  yield* fm.getValuesStream(
      (map) => Playing.fromMap(map), ["games", gameId, "playing"]);
}

Stream<List<ValueChange<Playing>>> readPlayingChange(String gameId) async* {
  yield* fm.getValuesChangeStream(
      (map) => Playing.fromMap(map), ["games", gameId, "playing"],
      order: ["order"], where: ["id", "!=", myId]);
}

Future<Game?> getGame(String gameId) async {
  return fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
}

Future<Match?> getLastMatch(String gameId) async {
  final matches = await fm
      .getValues((map) => Match.fromMap(map), ["games", gameId, "matches"]);
  return matches.isNotEmpty ? matches.last : null;
}

Future<Match?> getMatch(String gameId, String matchId) async {
  return fm.getValue(
      (map) => Match.fromMap(map), ["games", gameId, "matches", matchId]);
}

Future<List<Match>> getMatches(String gameId) async {
  return fm
      .getValues((map) => Match.fromMap(map), ["games", gameId, "matches"]);
}

Stream<List<Match>> readGameMatchesStream(String gameId) async* {
  yield* fm.getValuesStream(
      (map) => Match.fromMap(map), ["games", gameId, "matches"]);
}

Stream<List<GameList>> readGameLists() async* {
  yield* fm.getValuesStream(
      (map) => GameList.fromMap(map), ["users", myId, "gamelist"]);
}

Future<List<GameList>> readGames() async {
  return fm
      .getValues((map) => GameList.fromMap(map), ["users", myId, "gamelist"]);
}

Future<List<Match>> readGameMatches(String id) async {
  return fm.getValues((map) => Match.fromMap(map), ["games", id, "matches"]);
}

Stream<List<ValueChange<Map<String, dynamic>>>> streamChangeSignals(
    String id) async* {
  yield* fm.getValuesChangeStream((map) => map, ["games", id, "signal"],
      where: ["id", "!=", myId]);
}

Future addSignal(String id, String userId, Map<String, dynamic> value) {
  return fm.updateValue(["games", id, "signal", userId], value: value);
}

Future removeSignal(String id, String userId) {
  return fm.removeValue(["games", id, "signal", userId]);
}

String getGameId(List<String> players) {
  players.sort(((a, b) => a.compareTo(b)));
  int totalIdscount = 24;
  int splitSize = totalIdscount ~/ players.length;
  String id = "";
  for (int i = 0; i < players.length; i++) {
    final player = players[i];
    id += player.substring(player.length - splitSize);
    //id += player.substring(0, splitSize);
  }
  return id;
}
