import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:gamesarena/core/firebase/firebase_notification.dart';
import 'package:gamesarena/core/firebase/firestore_methods.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/models/models.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/utils/utils.dart';
import '../../shared/extensions/special_context_extensions.dart';
import '../../shared/services.dart';
import '../user/models/user.dart';
import '../user/services.dart';
import 'models/game.dart';
import 'models/game_list.dart';
import 'models/game_request.dart';
import 'models/player.dart';
import 'models/match.dart';

FirestoreMethods fm = FirestoreMethods();

Future<Game?> getGameFromPlayers(String playersString) async {
  List<String> playerIds =
      playersString.contains(",") ? playersString.split(",") : [playersString];
  if (!playerIds.contains(myId)) {
    playerIds.insert(0, myId);
  }
  String gameId = getGameId(playerIds);
  return fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
}

Future createGameGroup(String groupName, List<String> playerIds) async {
  final gameId = getId(["games"]);
  Game game = Game(
      game_id: gameId, groupName: groupName, time: timeNow, creatorId: myId);
  await fm.setValue(["games", gameId], value: game.toMap());
  //await addPlayerToGameGroup(gameId, myId);
  await addPlayersToGameGroup(gameId, playerIds);
}

Future deleteGameGroup(String gameId) async {
  await fm.updateValue(["games", gameId], value: {"time_deleted": timeNow});
}

Future exitGameGroup(String gameId) {
  return removePlayerFromGameGroup(gameId, myId);
}

Future updateGameGroupName(String gameId, String groupName) {
  return fm.updateValue(["games", gameId], value: {"groupName": groupName});
}

Future updateGameGroupProfilePhoto(String gameId, String profilePhoto) {
  return fm
      .updateValue(["games", gameId], value: {"profilePhoto": profilePhoto});
}

Future<List<Player>> addPlayersToGameGroup(
    String gameId, List<String> playerIds) async {
  List<Player> players = [];
  for (int i = 0; i < playerIds.length; i++) {
    final id = playerIds[i];

    final player = await addPlayerToGameGroup(gameId, id);
    players.add(player);
  }
  return players;
}

Future<Player> addPlayerToGameGroup(String gameId, String playerId) async {
  final player = Player(
      id: playerId,
      time: timeNow,
      role: playerId == myId ? "creator" : "participant");
  final gameList = GameList(game_id: gameId, time: timeNow);
  await fm.setValue(["users", playerId, "gamelist", gameId],
      value: gameList.toMap());
  await fm
      .setValue(["games", gameId, "players", playerId], value: player.toMap());
  if (playerId == myId) {
    Hive.box<String>("gamelists").put(gameId, gameList.toJson());
  }
  return player;
}

Future removePlayersFromGameGroup(String gameId, List<String> playerIds) async {
  for (int i = 0; i < playerIds.length; i++) {
    final id = playerIds[i];

    await removePlayerFromGameGroup(gameId, id);
  }
}

Future removePlayerFromGameGroup(String gameId, String playerId) async {
  final time = timeNow;
  await fm.updateValue(["users", playerId, "gamelist", gameId],
      value: {"time_end": time});
  await fm.removeValue(["games", gameId, "players", playerId]);
  if (playerId == myId) {
    final gameListBox = Hive.box<String>("gamelists");
    final prevGameListJson = gameListBox.get(gameId);
    if (prevGameListJson != null) {
      final prevGameList = GameList.fromJson(prevGameListJson);
      prevGameList.time_end = time;
      gameListBox.put(gameId, prevGameList.toJson());
      FirebaseNotification().unsubscribeFromTopic(gameId);
    }
  }
}

Future updatePlayerRole(String gameId, String playerId, String role) async {
  await fm.updateValue(["games", gameId, "players", playerId],
      value: {"role": role});
}

Future removeGameList(String gameId) async {
  await fm.removeValue(["users", myId, "gamelist", gameId]);
  Hive.box<String>("gamelists").delete(gameId);
}

Future updatePlayerRoleInGameGroup(
    String gameId, String playerId, String role) async {
  await fm.updateValue(["games", gameId, "players", playerId],
      value: {"role": role});
}

Future updateTimeStart(String gameId, String matchId, Match match) async {
  final time = timeNow;
  match.time_modified = time;
  sendPushNotification(gameId,
      notificationType: "match", isTopic: true, data: match.toMap());
  return fm.updateValue([
    "games",
    gameId,
    "matches",
    matchId
  ], value: {
    "time_start": match.time_start,
    "time_modified": match.time_modified
  });
}

Future updateMatch(Match match, Map<String, dynamic> matchMap) async {
  String gameId = match.game_id!;
  String matchId = match.match_id!;
  sendPushNotification(gameId,
      notificationType: "match", isTopic: true, data: match.toMap());
  return fm.updateValue(["games", gameId, "matches", matchId], value: matchMap);
}

Future updateScore(
    String gameId, String matchId, Match match, int recordId) async {
  final time = timeNow;
  match.time_modified = time;
  sendPushNotification(gameId,
      notificationType: "match", isTopic: true, data: match.toMap());
  return fm.updateValue([
    "games",
    gameId,
    "matches",
    matchId
  ], value: {
    "records": match.records,
    "time_modified": time,
    "outcome": match.outcome,
    "winners": match.winners,
    "others": match.others,
  });
  // return fm.updateValue(["games", gameId, "matches", matchId],
  //     value: {"records.$recordId.scores.$playerIndex": score, "time_modified": time});
}

Future updateLastSeen(String gameId, String time) {
  return fm.updateValue(["users", myId, "gamelist", gameId],
      value: {"lastSeen": time});
}

Future<Player> addPlayer(String playerId) async {
  final player = Player(id: playerId, time: timeNow);
  await fm
      .setValue(["users", myId, "players", playerId], value: player.toMap());
  return player;
}

Future<Match?> createMatch(
    String gameName, String? gameId, List<String> playerIds) async {
  if (playerIds.length < 2) {
    showErrorToast("Can't create match for only one user");
    return null;
  }
  final time = timeNow;

  if (gameId == null || gameId.isEmpty) {
    playerIds.sort(((a, b) => a.compareTo(b)));
    gameId = getGameId(playerIds);
  }
  final game = await fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
  if (game == null) {
    Game game = Game(
      game_id: gameId,
      time: time,
      creatorId: myId,
      players: playerIds,
      firstMatchTime: time,
    );
    await fm.setValue(["games", gameId], value: game.toMap());
    await addPlayersToGameGroup(gameId, playerIds);
  } else {
    if (game.firstMatchTime == null) {
      await fm.updateValue(["games", gameId], value: {"firstMatchTime": time});
    }
  }

  //playerIds.shuffle();

  String matchId = fm.getId(["games", gameId, "matches"]);

  final match = Match(
      match_id: matchId,
      game_id: gameId,
      creator_id: myId,
      games: [gameName],
      time_created: time,
      time_modified: time,
      players: playerIds,
      records: {},
      outcome: "");

  await fm.setValue(["games", gameId, "matches", matchId],
      value: match.toMap().removeNull());

  for (int i = 0; i < playerIds.length; i++) {
    String playerId = playerIds[i];
    await fm.updateValue([
      "games",
      gameId,
      "players",
      playerId
    ], value: {
      "action": playerId == myId ? "pause" : "",
      "order": i,
      "matchId": matchId,
      "gameId": gameId,
      "game": gameName,
      "callMode": null,
      "isAudioOn": null,
      "isFrontCamera": null,
      "time_modified": timeNow,
    });
  }

  // GameRequest request = GameRequest(
  //     game_id: gameId,
  //     match_id: matchId,
  //     game: gameName,
  //     creator_id: myId,
  //     time: timeNow);
  for (int i = 0; i < playerIds.length; i++) {
    final playerId = playerIds[i];

    final gameListsBox = Hive.box<String>("gamelists");

    if (gameListsBox.get(gameId) == null) {
      GameList? gameList = await fm.getValue((map) => GameList.fromMap(map),
          ["users", playerId, "gamelist", gameId]);
      if (gameList == null) {
        gameList = GameList(game_id: gameId, time: timeNow);
        await fm.setValue(["users", playerId, "gamelist", gameId],
            value: gameList.toMap());
      }
      gameListsBox.put(gameId, gameList.toJson());
    }

    if (playerId != myId) {
      // await fm.setValue(["users", playerId, "requests", myId],
      //     value: request.toMap());

      final playersBox = Hive.box<String>("players");

      if (playersBox.get(playerId) == null) {
        final time = timeNow;
        Player? player = await fm.getValue(
            (map) => Player.fromMap(map), ["users", myId, "players", playerId]);
        if (player == null) {
          player = Player(id: playerId, time: time);
          await fm.setValue(["users", myId, "players", playerId],
              value: player.toMap());
        }

        Player? otherPlayer = await fm.getValue(
            (map) => Player.fromMap(map), ["users", playerId, "players", myId]);
        if (otherPlayer == null) {
          otherPlayer = Player(id: myId, time: time);
          await fm.setValue(["users", playerId, "players", myId],
              value: otherPlayer.toMap());
        }
        playersBox.put(playerId, player.toJson());
      }
    }
  }

  sendPushNotificationToPlayers(gameId, gameName, playerIds, match);
  sendPushNotification(gameId,
      notificationType: "match", isTopic: true, data: match.toMap());

  Hive.box<String>("matches").put(match.match_id, match.toJson());
  return match;
}

Future sendPushNotificationToPlayers(
    String gameId, String game, List<String> players, Match match) async {
  final users = await playersToUsers(players);
  String creatorName = users.isEmpty
      ? ""
      : users.firstWhere((element) => element.user_id == myId).username;
  //players.remove(myId);
  users.removeWhere((element) => element.user_id == myId);
  for (int i = 0; i < players.length; i++) {
    final player = players[i];
    if (player == myId) continue;
    List<User> otherUsers =
        users.where((user) => user.user_id != player).toList();
    final otherUsernames =
        otherUsers.isEmpty ? [] : otherUsers.map((e) => e.username).toList();
    otherUsernames.insert(0, "you");

    final token = await getToken(player);
    //print("userToken = $token");

    if (token == null || token == "") return;
    final body =
        "$creatorName will like to play $game game with ${otherUsernames.toStringWithCommaandAnd((username) => username)}";
    sendPushNotification(token,
        title: creatorName,
        body: body,
        notificationType: "match",
        data: match.toMap());
  }
}

Future cancelMatch(String gameId, String matchId, List<Player> players) async {
  if (players.isEmpty) return;

  // await fm.removeValues(
  //     ["games", gameId, "players"], players.map((e) => e.id).toList());
  ////await removeGamedetails(gameId, matchId);
  for (int i = 0; i < players.length; i++) {
    final player = players[i];
    //await fm.removeValue(["users", player.id, "game"]);
    await fm.updateValue([
      "games",
      gameId,
      "players",
      player.id
    ], value: {
      "action": "",
      "matchId": "",
      "gameId": "",
      "game": null,
      "time_modified": timeNow
    });
  }
}

Future joinMatch(
    String gameId, String matchId, String game, List<Player> players) async {
  await fm.updateValue(["games", gameId, "players", myId],
      value: {"action": "pause", "time_modified": timeNow});
  //value: {"accept": true, "time": timeNow});

  final unstartedPlayers =
      players.where((element) => element.action != "pause");
  if (unstartedPlayers.length == 1) {
    // await addMatchRecord(game, gameId, matchId, players, 0);
    // await fm.updateValue(["games", gameId, "matches", matchId],
    //     value: {"time_start": timeNow, "players": players});
  }
}

Future leaveMatch(
    String gameId, String matchId, Match? match, List<Player> players) async {
  if (players.isEmpty) return;
  final time = timeNow;

  final activePlayers = players.where((element) => element.action != "");

  if (activePlayers.length < 2) {
    await fm.updateValue(["games", gameId, "matches", matchId],
        value: {"time_end": time, "time_modified": time});
    if (match != null) {
      match.time_end = time;
      match.time_modified = time;
      sendPushNotification(gameId,
          notificationType: "match", isTopic: true, data: match.toMap());
    }
  }

  await fm.updateValue([
    "games",
    gameId,
    "players",
    myId
  ], value: {
    "action": "",
    "matchId": "",
    "gameId": "",
    "game": null,
    "time_modified": timeNow
  });
}

Future updatePlayerAction(String gameId, String matchId, String action,
    [String? game]) async {
  return fm.updateValue([
    "games",
    gameId,
    "players",
    myId
  ], value: {
    "action": action,
    if (game != null) ...{"game": game},
    "time_modified": timeNow
  });
}

// Future startGame(String game, String gameId, String matchId) async {
//   await fm.updateValue(["games", gameId, "players", myId],
//       value: {"action": "start", "game": game, "time_modified": timeNow});
// }

// Future restartGame(String game, String gameId, String matchId) async {
//   await fm.updateValue(["games", gameId, "players", myId],
//       value: {"action": "restart", "game": game, "time_modified": timeNow});
// }

// Future changeGame(String game, String gameId, String matchId) async {
//   await fm.updateValue(["games", gameId, "players", myId],
//       value: {"game": game, "action": "pause", "time_modified": timeNow});
// }

// Future pauseGame(String gameId, String matchId) async {
//   await fm.updateValue(["games", gameId, "players", myId],
//       value: {"action": "pause", "time_modified": timeNow});
// }

// Future concedeGame(String gameId, String matchId) async {
//   await fm.updateValue(["games", gameId, "players", myId],
//       value: {"action": "concede", "time_modified": timeNow});
// }

Stream<GameRequest?> getGameRequest() async* {
  yield* fm.getValueStream((map) => GameRequest.fromMap(map), [
    "users",
    myId,
    "game"
  ], queries: [
    ["order", "time", true],
    ["limit", 1]
  ]);
}

Future<GameRequest?> checkGameRequest(String id) async {
  return fm
      .getValue((map) => GameRequest.fromMap(map), ["users", id, "requests"]);
}

Future<List<Player>> getMyPlayers({String? startTime, String? endTime}) async {
  return fm.getValues((map) => Player.fromMap(map), [
    "users",
    myId,
    "players"
  ], queries: [
    ["order", "time", true],
    [
      "where",
      if (startTime != null) ...["time", ">", startTime],
      if (endTime != null) ...["time", "<", endTime]
    ],
    if (startTime != null || endTime != null) ["limit", 10, startTime != null]
  ]);
}

Future<List<Player>> getPlayers(String gameId,
    {String? matchId,
    bool excludingMe = true,
    String? startTime,
    String? endTime}) async {
  return fm.getValues(
    (map) => Player.fromMap(map),
    ["games", gameId, "players"],
    queries: [
      ["order", matchId != "" ? "order" : "time_modified"],
      [
        "where",
        if (excludingMe) ...["id", "!=", myId],
        if (matchId != "" && matchId != null) ...["matchId", "==", matchId],
        if (startTime != null) ...["time_modified", "<", startTime],
        if (endTime != null) ...["time_modified", ">", endTime]
      ],
      if (startTime != null || endTime != null) ["limit", 10, startTime != null]
    ],
  );
}

Stream<List<ValueChange<Player>>> getPlayersChange(String gameId,
    {String? matchId,
    String? lastTime,
    bool excludingMe = true,
    List<String>? players}) async* {
  yield* fm.getValuesChangeStream(
    (map) => Player.fromMap(map),
    ["games", gameId, "players"],
    queries: [
      ["order", matchId != "" ? "order" : "time_modified"],
      [
        "where",
        if (players != null) ...[
          "id",
          "in",
          excludingMe
              ? players.where((element) => element != myId).toList()
              : players
        ],
        if (excludingMe && players == null) ...["id", "!=", myId],
        if (matchId != "") ...["matchId", "==", matchId],
        if (lastTime != null) ...["time_modified", ">", lastTime],
      ]
    ],
  );
}

Future<Game?> getGame(String gameId) async {
  final game = await fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
  // if(game != null game.groupName == null){
  // }
  return game;
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

Stream<List<ValueChange<Player>>> getPlayerRequestStream() async* {
  yield* fm.getValuesChangeStream((map) => Player.fromMap(map), ["players"],
      isSubcollection: true,
      queries: [
        ["order", "time_modified", false],
        ["where", "id", "==", myId],
        ["where", "matchId", "!=", ""],
        ["where", "action", "==", ""],
        ["limit", 1, true]
      ]);
}

Future<List<Player>> getPlayerRequest() async {
  return fm.getValues((map) => Player.fromMap(map), ["players"],
      isSubcollection: true,
      queries: [
        ["order", "time_modified", false],
        ["where", "id", "==", myId],
        ["where", "matchId", "!=", ""],
        ["where", "action", "==", ""],
        ["limit", 1, true]
      ]);
}

Future<bool> isPlayingAMatch(String playerId) async {
  // final matches = await fm.getValues(
  //     (map) => map,
  //     [
  //       "matches",
  //     ],
  //     isSubcollection: true,
  //     queries: [
  //       ["order", "time_modified", false],
  //       ["where", "players", "contains", playerId],
  //       ["where", "creator_id", "!=", myId],
  //       ["where", "time_end", "==", null]
  //     ]);
  final players = await fm.getValues((map) => Player.fromMap(map), ["players"],
      isSubcollection: true,
      queries: [
        ["order", "time_modified", false],
        ["where", "id", "==", playerId],
        ["where", "action", "==", ""],
        ["where", "matchId", "!=", ""],
        ["limit", 1, true]
      ]);
  return players.isNotEmpty;
}

Stream<List<ValueChange<Match>>> getRequestedMatchesStream() async* {
  yield* fm.getValuesChangeStream(
      (map) => Match.fromMap(map),
      [
        "matches",
      ],
      isSubcollection: true,
      queries: [
        ["order", "time_modified", false],
        ["where", "players", "contains", myId],
        ["where", "creator_id", "!=", myId],
        ["where", "time_end", "==", null]
      ]);
}

Future<List<Match>> getRequestedMatches() async {
  return fm.getValues(
      (map) => Match.fromMap(map),
      [
        "matches",
      ],
      isSubcollection: true,
      queries: [
        ["order", "time_modified", false],
        ["where", "players", "contains", myId],
        ["where", "creator_id", "!=", myId],
        ["where", "time_end", "==", null]
      ]);
}

Future<List<Match>> getMatchesFromGameIds(List<String> gameIds,
    {String? time}) async {
  return fm.getValues((map) => Match.fromMap(map), ["matches"],
      queries: [
        ["order", "game_id", false],
        ["where", "game_id", "in", gameIds],
        ["order", "time_modified", false],
        if (time != null) ...["where", "time_modified", ">", time]
      ],
      isSubcollection: true);
}

Future<List<Match>> getMatches(String gameId,
    {String? time, int? limit}) async {
  return fm.getValues((map) => Match.fromMap(map), [
    "games",
    gameId,
    "matches"
  ], queries: [
    ["order", "time_modified", false],
    if (time != null) ["where", "time_modified", ">", time],
    if (limit != null) ["limit", limit, false]
  ]);
}

Future<List<Match>> getPreviousMatches(String gameId,
    {String? time, int? limit}) async {
  return fm.getValues((map) => Match.fromMap(map), [
    "games",
    gameId,
    "matches"
  ], queries: [
    ["order", "time_created", false],
    if (time != null) ["where", "time_created", "<", time],
    if (limit != null) ["limit", limit, true]
  ]);
}

Stream<List<ValueChange<Match>>> getMatchesChange(String gameId,
    {String? time}) async* {
  yield* fm.getValuesChangeStream((map) => Match.fromMap(map), [
    "games",
    gameId,
    "matches"
  ], queries: [
    ["order", "time_created", false],
    if (time != null) ["where", "time_modified", ">", time]
  ]);
}

Stream<List<Match>> getGameMatchesStream(String gameId) async* {
  yield* fm.getValuesStream(
      (map) => Match.fromMap(map), ["games", gameId, "matches"]);
}

Future<List<GameList>> getGameLists({String? time}) async {
  return fm.getValues((map) => GameList.fromMap(map), [
    "users",
    myId,
    "gamelist"
  ], queries: [
    ["order", "time", false],
    if (time != null) ["where", "time", "", time]
  ]);
}

Stream<List<ValueChange<GameList>>> getGameListsChange({String? time}) async* {
  yield* fm.getValuesChangeStream((map) => GameList.fromMap(map), [
    "users",
    myId,
    "gamelist"
  ], queries: [
    ["order", "time", false],
    if (time != null) ["where", "time", ">", time]
    // "lastSeen",
    // "==",
    // null
  ]);
}

Future<List<Match>> getGameMatches(String id) async {
  return fm.getValues((map) => Match.fromMap(map), ["games", id, "matches"]);
}

Future startCall(String gameId, String callMode) {
  return fm.updateValue([
    "games",
    gameId,
    "players",
    myId
  ], value: {
    "callMode": callMode,
    "isAudioOn": true,
    "isFrontCamera": true,
    "time_modified": timeNow, // "id": myId,
  });
}

Future endCall(String gameId) {
  return fm.updateValue([
    "games",
    gameId,
    "players",
    myId
  ], value: {
    "callMode": null,
    "isAudioOn": null,
    "isFrontCamera": null,
    "time_modified": timeNow
  });
}

Future updateCallMode(String gameId, String matchId, String? callMode) {
  return fm.updateValue(["games", gameId, "players", myId],
      value: {"callMode": callMode, "time_modified": timeNow});
}

Future updateCallAudio(String gameId, String matchId, bool isAudioOn) {
  return fm.updateValue(["games", gameId, "players", myId],
      value: {"isAudioOn": isAudioOn, "time_modified": timeNow});
}

Future updateCallCamera(String gameId, String matchId, bool isFrontCamera) {
  return fm.updateValue(["games", gameId, "players", myId],
      value: {"isFrontCamera": isFrontCamera, "time_modified": timeNow});
}

// Future addSignal(String gameId, String userId, Map<String, dynamic> value) {
//   return fm.updateValue([
//     "games",
//     gameId,
//     "players",
//     userId
//   ], value: {
//     "signal": {...value, "id": myId}
//   });
// }

Stream<List<ValueChange<Map<String, dynamic>>>> streamChangeSignals(
    String gameId, String matchId) async* {
  yield* fm.getValuesChangeStream(
      (map) => map, ["games", gameId, "players", myId, "signal"]);
}

Future addSignal(String gameId, String matchId, String userId,
    Map<String, dynamic> value) async {
  return fm.setValue(["games", gameId, "players", userId, "signal", myId],
      value: {...value, "id": myId});
}

Future removeSignal(String gameId, String matchId, String userId) {
  return fm.removeValue(["games", gameId, "players", userId, "signal"]);
}

String getGameId(List<String> players) {
  players.sort(((a, b) => a.compareTo(b)));
  int totalIdscount = 24;
  int splitSize = totalIdscount ~/ players.length;
  String id = "";
  for (int i = 0; i < players.length; i++) {
    final player = players[i];
    //id += player.substring(players.length - splitSize);
    id += player.substring(0, splitSize);
  }
  return id;
}
