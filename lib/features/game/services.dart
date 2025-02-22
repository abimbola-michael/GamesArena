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
import '../../main.dart';
import '../../shared/extensions/special_context_extensions.dart';
import '../../shared/services.dart';
import '../records/services.dart';
import '../user/services.dart';

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

Future<GameList> createGameGroup(
    String groupName, List<String> playerIds) async {
  if (!playerIds.contains(myId)) {
    playerIds.insert(0, myId);
  }
  final gameId = getId(["games"]);
  final time = timeNow;
  Game game = Game(
      game_id: gameId,
      groupName: groupName,
      time_created: time,
      time_modified: time,
      user_id: myId,
      creatorId: myId);
  await fm.setValue(["games", gameId], value: game.toMap().removeNull());
  final players = await addPlayersToGameGroup(gameId, playerIds);
  final gameList = players.firstWhere((player) => player.id == myId).gameList;
  gameList!.game = game;
  return gameList;
}

Future deleteGameGroup(String gameId) async {
  final time = timeNow;
  await fm.updateValue(["games", gameId],
      value: {"time_deleted": time, "time_modified": time, "user_id": myId});
}

// Future exitGameGroup(String gameId) {
//   return removePlayerFromGameGroup(gameId, myId);
// }

Future updateGameGroupName(String gameId, String groupName, [String? time]) {
  time ??= timeNow;
  return fm.updateValue(["games", gameId],
      value: {"groupName": groupName, "time_modified": time, "user_id": myId});
}

Future updateGameGroupProfilePhoto(String gameId, String profilePhoto) {
  final time = timeNow;
  return fm.updateValue([
    "games",
    gameId
  ], value: {
    "profilePhoto": profilePhoto,
    "time_modified": time,
    "user_id": myId
  });
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
  final time = timeNow;
  final player = Player(
      id: playerId,
      time: time,
      role: playerId == myId ? "creator" : "participant");

  final gameList = GameList(
      game_id: gameId, time_created: time, time_modified: time, user_id: myId);

  player.gameList = gameList;

  await fm.setValue(["users", playerId, "gamelist", gameId],
      value: gameList.toMap().removeNull());
  await fm
      .setValue(["games", gameId, "players", playerId], value: player.toMap());

  return player;
}

Future removePlayersFromGameGroup(String gameId, List<String> playerIds) async {
  for (int i = 0; i < playerIds.length; i++) {
    final id = playerIds[i];

    await removePlayerFromGameGroup(gameId, id);
  }
}

Future removePlayerFromGameGroup(String gameId, String playerId,
    [String? time]) async {
  time ??= timeNow;
  await fm.updateValue(["users", playerId, "gamelist", gameId],
      value: {"time_end": time, "time_modified": time, "user_id": myId});
  return fm.removeValue(["games", gameId, "players", playerId]);
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

Future updateMatch(Match match) async {
  String gameId = match.game_id!;
  String matchId = match.match_id!;

  sendPushNotification(gameId,
      notificationType: "match", isTopic: true, data: match.toMap());

  await fm
      .updateValue(["games", gameId, "matches", matchId], value: match.toMap());
}

// Future updateScore(
//     String gameId, String matchId, Match match, int recordId) async {
//   final time = timeNow;
//   match.time_modified = time;
//   sendPushNotification(gameId,
//       notificationType: "match", isTopic: true, data: match.toMap());
//   return fm.updateValue([
//     "games",
//     gameId,
//     "matches",
//     matchId
//   ], value: {
//     "records": match.records,
//     "time_modified": time,
//     "outcome": match.outcome,
//     "winners": match.winners,
//     "others": match.others,
//   });
// return fm.updateValue(["games", gameId, "matches", matchId],
//     value: {"records.$recordId.scores.$playerIndex": score, "time_modified": time});
//}

Future updateInfosSeen(String gameId, String time) {
  return fm.updateValue(["users", myId, "gamelist", gameId],
      value: {"time_seen": time, "time_modified": timeNow});
}

Future<Player> addPlayer(String playerId) async {
  final player = Player(id: playerId, time: timeNow);
  await fm
      .setValue(["users", myId, "players", playerId], value: player.toMap());

  await fm.setValue(["users", playerId, "players", myId],
      value: player.copyWith(id: myId).toMap());
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
    gameId = getGameId(playerIds);
  }
  final gameListsBox = Hive.box<String>("gamelists");

  var gameListJson = gameListsBox.get(gameId);
  if (gameListJson == null) {
    final game =
        await fm.getValue((map) => Game.fromMap(map), ["games", gameId]);

    if (game == null) {
      Game game = Game(
          game_id: gameId,
          time_created: time,
          time_modified: time,
          user_id: myId,
          creatorId: myId,
          players: playerIds);
      await fm.setValue(["games", gameId], value: game.toMap().removeNull());
      await addPlayersToGameGroup(gameId, playerIds);
    }
  }

  playerIds.shuffle();

  String matchId = fm.getId(["games", gameId, "matches"]);

  final match = Match(
      match_id: matchId,
      game_id: gameId,
      creator_id: myId,
      games: [gameName],
      time_created: time,
      time_modified: time,
      players: playerIds,
      // records: {},
      user_id: myId,
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

  for (int i = 0; i < playerIds.length; i++) {
    final playerId = playerIds[i];

    final gameListsBox = Hive.box<String>("gamelists");

    if (gameListsBox.get(gameId) == null) {
      GameList? gameList = await fm.getValue((map) => GameList.fromMap(map),
          ["users", playerId, "gamelist", gameId]);
      if (gameList == null) {
        gameList = GameList(
            game_id: gameId,
            time_created: time,
            time_modified: time,
            // time_start: time,
            user_id: playerId);
        await fm.setValue(["users", playerId, "gamelist", gameId],
            value: gameList.toMap().removeNull());
      }
      await gameListsBox.put(gameId, gameList.toJson());
    }

    if (playerId != myId) {
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

  return match;
}

Future sendPushNotificationToPlayers(
    String gameId, String game, List<String> players, Match match) async {
  sendPushNotification(gameId,
      notificationType: "match", isTopic: true, data: match.toMap());

  Hive.box<String>("matches").put(match.match_id, match.toJson());

  final users = await playersToUsers(players);
  String creatorName = users
          .firstWhereNullable((element) => element.user_id == myId)
          ?.username ??
      "";
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

    //print("userToken = $token");

    final body =
        "will like to play $game game with ${otherUsernames.toStringWithCommaandAnd((username) => username)}";
    sendUserPushNotification(player,
        title: creatorName, body: body, notificationType: "match");
  }
}

Future<Match> cancelMatch(Match match, List<Player> players) async {
  String gameId = match.game_id!;
  String matchId = match.match_id!;

  final time = timeNow;

  for (int i = 0; i < players.length; i++) {
    final player = players[i];
    fm.updateValue([
      "games",
      gameId,
      "players",
      player.id
    ], value: {
      "action": "",
      "matchId": "",
      "gameId": "",
      "game": null,
      "time_modified": time
    });
  }

  match.time_end = time;
  match.available_players = [];
  match.time_modified = time;
  match.user_id = myId;

  sendPushNotification(gameId,
      notificationType: "match", isTopic: true, data: match.toMap());

  fm.updateValue([
    "games",
    gameId,
    "matches",
    matchId
  ], value: {
    "time_end": time,
    "time_modified": time,
    "available_players": match.available_players,
    "user_id": myId
  });
  return match;
}

Future<Match> joinMatch(Match match, String game, List<Player> players) async {
  String gameId = match.game_id!;
  String matchId = match.match_id!;
  await fm.updateValue([
    "games",
    gameId,
    "players",
    myId
  ], value: {
    "action": "pause",
    "matchId": matchId,
    "gameId": gameId,
    "game": game,
    "time_modified": timeNow
  });
  return match;
}

Future<Match> leaveMatch(Match match, List<Player> players,
    [bool endMatch = true]) async {
  String gameId = match.game_id!;
  String matchId = match.match_id!;
  final time = timeNow;

  final activePlayers = players
      .where((player) => player.action != "" && player.matchId == matchId)
      .toList();

  fm.updateValue([
    "games",
    gameId,
    "players",
    myId
  ], value: {
    "action": "",
    "matchId": "",
    "gameId": "",
    "game": null,
    "time_modified": time
  });
  match.available_players?.remove(myId);

  activePlayers.removeWhere((player) => player.id == myId);

  if (activePlayers.length == 1) {
    final otherId = activePlayers.first.id;
    fm.updateValue([
      "games",
      gameId,
      "players",
      otherId
    ], value: {
      "action": "",
      "matchId": "",
      "gameId": "",
      "game": null,
      "time_modified": time
    });
    activePlayers.removeWhere((player) => player.id == otherId);
    match.available_players?.remove(otherId);
  }

  if (activePlayers.isEmpty) {
    match.time_end = time;
  }
  match.time_modified = time;
  match.user_id = myId;

  sendPushNotification(gameId,
      notificationType: "match", isTopic: true, data: match.toMap());
  fm.updateValue([
    "games",
    gameId,
    "matches",
    matchId
  ], value: {
    "time_end": match.time_end,
    "time_modified": time,
    "available_players": match.available_players,
    "user_id": myId
  });

  return match;
}

Future updatePlayerAction(String gameId, String matchId, String action,
    {String? game, String? difficulty, String? exemptedRules}) async {
  return fm.updateValue([
    "games",
    gameId,
    "players",
    myId
  ], value: {
    "action": action,
    "matchId": matchId,
    "gameId": gameId,
    if (game != null) ...{"game": game},
    if (difficulty != null) ...{"difficulty": difficulty},
    if (exemptedRules != null) ...{"exemptedRules": exemptedRules},
    "time_modified": timeNow,
    if (action.isEmpty) ...{
      "matchId": "",
      "gameId": "",
      "game": null,
      "difficulty": null,
      "exemptedRules": exemptedRules,
    }
  });
}

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
      [
        "where",
        if (excludingMe) ...["id", "!=", myId],
        if (matchId != "" && matchId != null) ...["matchId", "==", matchId],
        if (startTime != null) ...["time", "<", startTime],
        if (endTime != null) ...["time", ">", endTime]
      ],
      ["order", "time"],
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
      [
        "where",
        if (players != null) ...[
          "id",
          "in",
          excludingMe ? players.where((id) => id != myId).toList() : players
        ] else if (excludingMe) ...[
          "id",
          "!=",
          myId
        ],
        if (matchId != "") ...["matchId", "==", matchId],
        if (lastTime != null) ...["time_modified", ">", lastTime],
      ],
      ["order", "order"],
    ],
  );
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

Stream<List<ValueChange<Match>>> getMatchesChange(String gameId,
    {String? time}) async* {
  yield* fm.getValuesChangeStream((map) => Match.fromMap(map), [
    "games",
    gameId,
    "matches"
  ], queries: [
    ["order", "time_modified", false],
    if (time != null) ["where", "time_modified", ">", time],
    ["where", "user_id", "!=", myId],
  ]);
}

Stream<List<ValueChange<Match>>> getAllMatchesChange(List<String> gameIds,
    {String? time}) async* {
  yield* fm.getValuesChangeStream((map) => Match.fromMap(map), ["matches"],
      isSubcollection: true,
      queries: [
        ["where", "in", gameIds],
        ["order", "time_modified", false],
        if (time != null) ["where", "time_modified", ">", time],
        ["where", "user_id", "!=", myId],
      ]);
}

Future<List<Match>> getMatches(String gameId,
    {String? time, String? timeEnd, int? limit}) async {
  return fm.getValues((map) => Match.fromMap(map), [
    "games",
    gameId,
    "matches"
  ], queries: [
    ["order", "time_modified", false],
    if (time != null) ["where", "time_modified", ">", time],
    if (timeEnd != null) ["where", "time_modified", "<", timeEnd],
    if (limit != null) ["limit", limit, false]
  ]);
}

Future<List<Match>> getPreviousMatches(String gameId,
    {String? timeEnd, String? timeStart, String type = "", int? limit}) async {
  return fm.getValues((map) => Match.fromMap(map), [
    "games",
    gameId,
    "matches"
  ], queries: [
    ["order", "time_created", true],
    if (type.isNotEmpty)
      [
        "where",
        ...getPlayedMatchesQueries(type),
      ],
    if (timeEnd != null) ["where", "time_created", "<", timeEnd],
    if (timeStart != null) ["where", "time_created", ">", timeStart],
    if (limit != null) ["limit", limit]
  ]);
}

Stream<List<Match>> getGameMatchesStream(String gameId) async* {
  yield* fm.getValuesStream(
      (map) => Match.fromMap(map), ["games", gameId, "matches"]);
}

Future<List<GameList>> getGameLists({String? time, String? timeEnd}) async {
  return fm.getValues((map) => GameList.fromMap(map), [
    "users",
    myId,
    "gamelist"
  ], queries: [
    ["order", "time_modified", true],
    if (time != null) ["where", "time_modified", ">", time],
    if (timeEnd != null) ["where", "time_modified", "<", timeEnd],
  ]);
}

Stream<List<ValueChange<GameList>>> getGameListsChange(
    {String? time, String? timeEnd}) async* {
  yield* fm.getValuesChangeStream((map) => GameList.fromMap(map), [
    "users",
    myId,
    "gamelist"
  ], queries: [
    ["order", "time_modified", true],
    if (time != null) ["where", "time_modified", ">", time],
    if (timeEnd != null) ["where", "time_modified", "<", timeEnd],
    ["where", "user_id", "!=", myId]
  ]);
}

Future updateGameListTime(String gameId,
    {String? timeStart,
    String? timeEnd,
    String? timeSeen,
    String? time}) async {
  if (timeStart == null && timeEnd == null && timeSeen == null) {
    return;
  }
  // final time = timeSeen != null ? timeNow : timeEnd ?? timeStart ?? timeNow;
  // final time = timeEnd ?? timeSeen ?? timeStart ?? timeNow;

  return fm.updateValue([
    "users",
    myId,
    "gamelist",
    gameId
  ], value: {
    if (timeSeen != null) "time_seen": timeSeen,
    if (timeStart != null) "time_start": timeStart,
    if (timeEnd != null) "time_end": timeEnd,
    "time_modified": time ?? timeNow,
    "user_id": myId,
  });
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
  if (players.isEmpty) return "";
  if (players.length == 1) return players.first;
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
