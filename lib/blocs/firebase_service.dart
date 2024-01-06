import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gamesarena/blocs/firebase_methods.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';

import '../models/private_key.dart';
import '../models/games/batball.dart';
import '../models/games/chess.dart';
import '../models/games/draught.dart';
import '../models/games/ludo.dart';
import '../models/games/whot.dart';
import '../models/games/xando.dart';
import '../models/models.dart';
import '../models/player.dart';
import '../utils/utils.dart';

class FirebaseService {
  FirebaseMethods fm = FirebaseMethods();
  String myId = "";
  String timeNow = DateTime.now().millisecondsSinceEpoch.toString();

  FirebaseService() {
    myId = fm.myId;
  }
  Future sendPushNotification(String game, List<String> players) async {
    final users = await playersToUsers(players);
    String creatorName =
        users.firstWhere((element) => element.user_id == myId).username;
    players.remove(myId);
    users.removeWhere((element) => element.user_id == myId);
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      List<User> otherUsers =
          users.where((user) => user.user_id != player).toList();
      final otherUsernames =
          otherUsers.isEmpty ? [] : otherUsers.map((e) => e.username).toList();
      otherUsernames.insert(0, "you");
      final key = await getPrivateKey();
      if (key == null) return;
      String firebaseAuthKey = key.firebaseAuthKey;
      final token = await getToken(player);
      //final phoneToken = await FirebaseMessaging.instance.getToken();
      //phoneToken == token
      if (token == null || token == "") return;
      final body =
          "$creatorName will like to play $game game with ${otherUsernames.toStringWithCommaandAnd((username) => username)}";
      try {
        await post(
          Uri.parse("https://fcm.googleapis.com/fcm/send"),
          headers: <String, String>{
            "Content-Type": "application/json",
            "Authorization": "key=$firebaseAuthKey",
          },
          body: jsonEncode(<String, dynamic>{
            "priority": "high",
            "data": <String, dynamic>{
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
              "status": "done",
              "body": body,
              "title": creatorName,
            },
            "notification": <String, dynamic>{
              "body": body,
              "title": creatorName,
              "android_channel_id": CHANNEL_ID,
            },
            "to": token,
          }),
        );
      } catch (e) {}
    }
  }

  String getId(List<String> path) {
    return fm.getId(path);
  }

  Future<PrivateKey?> getPrivateKey() async {
    return fm.getValue((map) => PrivateKey.fromMap(map), ["admin", "keys"]);
  }

  void updateToken(String token) async {
    if (kIsWeb) return;
    if (myId != "") {
      await fm.setValue(["users", myId], value: {"token": token}, update: true);
    }
  }

  Future<String?> getToken(String userId) async {
    return fm.getValue((map) => map["token"], ["users", userId]);
  }

  Future sendNotification(String userId) async {
    final token = await getToken(userId);
    if (token == null) return;
  }

  Future updateUserDetails(String type, String value) async {
    return fm.setValue(["users", myId], value: {type: value}, update: true);
  }

  Future createUser(User user) async {
    await fm.setValue(["users", user.user_id], value: user.toMap());
  }

  Future creatGroup(Group group, List<String> players) async {
    String groupId = group.group_id;
    players.insert(0, myId);
    await fm.setValue(["groups", groupId], value: group.toMap());

    if (players.isNotEmpty) {
      for (var id in players) {
        final player = Player(id: id, time: timeNow);
        await fm.setValue(["groups", groupId, "players", id],
            value: player.toMap());
      }
    }
  }

  Future<List<Player>> readPlayers() async {
    return fm
        .getValues((map) => Player.fromMap(map), ["users", myId, "players"]);
  }

  Future<List<Player>> readGroupPlayers(String groupId) async {
    return fm.getValues(
        (map) => Player.fromMap(map), ["groups", groupId, "players"]);
  }

  Stream<User?> getStreamUser(String userId) async* {
    yield* fm
        .getStreamValue<User>((map) => User.fromMap(map), ["users", userId]);
  }

  Future<User?> getUser(String userId) async {
    return fm.getValue<User>((map) => User.fromMap(map), ["users", userId]);
  }

  Stream<Group?> getStreamGroup(String groupId) async* {
    yield* fm.getStreamValue<Group>(
        (map) => Group.fromMap(map), ["groups", groupId]);
  }

  Future<Group?> getGroup(String groupId) async {
    return fm.getValue<Group>((map) => Group.fromMap(map), ["groups", groupId]);
  }

  Future<List<User>> searchUser(String type, String searchString) async {
    return fm.getValues<User>((map) => User.fromMap(map), ["users"],
        where: [type, "==", searchString.toLowerCase().trim()]);
  }

  Future<Group?> searchGroup(String type, String searchString) async {
    final groups = await fm.getValues<Group>(
        (map) => Group.fromMap(map), ["groups"],
        where: [type, "==", searchString]);
    return groups.isNotEmpty ? groups.first : null;
  }

  Future<List<User>> playersToUsers(List<String> players) async {
    List<User> users = [];
    if (players.isNotEmpty) {
      for (var player in players) {
        final user = await getUser(player);
        if (user != null) users.add(user);
      }
    }
    return users;
  }

  Future<List<User?>> playingToUsers(List<Playing> playing) async {
    List<User?> users = [];
    if (playing.isNotEmpty) {
      for (var player in playing) {
        final user = await getUser(player.id);
        users.add(user);
      }
    }
    return users;
  }

  Future<Game?> getGameFromPlayers(String playersString) async {
    List<String> playerIds = playersString.contains(",")
        ? playersString.split(",")
        : [playersString];
    if (!playerIds.contains(myId)) {
      playerIds.insert(0, myId);
    }
    String gameId = getGameId(playerIds);
    return fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
  }

  Future<List<User>> getPlayersFromGame(String gameId) async {
    final game =
        await fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
    if (game == null) return [];
    final players = game.players;
    final playerIds = players.split(",");
    return playersToUsers(playerIds);
  }

  String getGameId(List<String> players) {
    players.sort(((a, b) => a.compareTo(b)));
    int totalIdscount = 24;
    int splitSize = totalIdscount ~/ players.length;
    String id = "";
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      id += player.substring(player.length - splitSize);
    }
    return id;
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
    final game =
        await fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
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
    if (gameName == "Ludo" || gameName == "Whot") {
      await createGameDetails(gameName, gameId);
    }

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
    await sendPushNotification(gameName, playerIds);
    return request;
  }

  Future createGameDetails(String game, String gameId) async {
    if (game == "Chess") {
      return setChessDetails(gameId);
    } else if (game == "Draught") {
      return setDraughtDetails(gameId);
    } else if (game == "Bat Ball") {
      return setBatBallDetails(gameId);
    } else if (game == "X and O") {
      return setXandODetails(gameId);
    } else if (game == "Whot") {
      return setWhotDetails(gameId);
    } else if (game == "Ludo") {
      return setLudoDetails(gameId);
    }
  }

  Future cancelGame(
      String gameId, String matchId, List<Playing> playing) async {
    await fm.removeValue(["games", gameId, "playing"]);
    await fm.removeValue(["games", gameId, "details"]);
    for (var player in playing) {
      await fm.removeValue(["users", player.id, "game"]);
    }
  }

  Future joinGame(String gameId, String matchId) async {
    await fm.setValue(["games", gameId, "playing", myId],
        value: {"accept": true, "time": timeNow}, update: true);
  }

  Future leaveGame(String gameId, String matchId, List<Playing> playing,
      bool started, int id, int duration) async {
    if (started) {
      if (playing.length == 2) {
        await fm.setValue(["games", gameId, "matches", matchId],
            value: {"time_end": timeNow}, update: true);
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
    await fm.setValue(["games", gameId, "playing", myId],
        value: {"action": "start", "game": game}, update: true);
    if (!started) {
      final unstartedPlayers =
          playing.where((element) => element.action != "start");
      if (unstartedPlayers.length == 1) {
        await addMatchRecord(game, gameId, matchId, playing, id);
        if (id == 0) {
          await fm.setValue(["games", gameId, "matches", matchId],
              value: {"time_start": timeNow}, update: true);
        }
      }
    }
  }

  Future restartGame(String game, String gameId, String matchId,
      List<Playing> playing, int id, int duration) async {
    await fm.setValue(["games", gameId, "playing", myId],
        value: {"action": "restart", "game": game}, update: true);

    final unrestartedPlayers =
        playing.where((element) => element.action != "restart");
    if (unrestartedPlayers.length == 1) {
      await fm.setValue(["games", gameId, "matches", matchId, "records", "$id"],
          value: {"time_end": timeNow, "duration": duration}, update: true);

      await addMatchRecord(game, gameId, matchId, playing, id + 1);
    }
  }

  Future changeGame(String game, String gameId, String matchId,
      List<Playing> playing, int id, int duration) async {
    final gamePlayers = playing.where((element) => element.game != game);
    if (gamePlayers.length == 1) {
      await fm.setValue(["games", gameId, "matches", matchId, "records", "$id"],
          value: {"time_end": timeNow, "duration": duration}, update: true);
      await fm.removeValue(["games", gameId, "details"]);
      await createGameDetails(game, gameId);
    }
    await fm.setValue(["games", gameId, "playing", myId],
        value: {"game": game, "action": "pause"}, update: true);
  }

  Future pauseGame(String gameId, String matchId, List<Playing> playing, int id,
      int duration) async {
    if (playing.isNotEmpty) {
      for (var player in playing) {
        if (player.action != "pause") {
          await fm.setValue(["games", gameId, "playing", player.id],
              value: {"action": "pause"}, update: true);
          await fm.setValue(
              ["games", gameId, "matches", matchId, "records", "$id"],
              value: {"duration": duration}, update: true);
        }
      }
    }
  }

  Future removeGameRequest() async {
    await fm.removeValue(["users", myId, "game"]);
  }

  Future<MatchRecord?> getMatchRecord(
      String gameId, String matchId, int id) async {
    return fm.getValue((map) => MatchRecord.fromMap(map),
        ["games", gameId, "matches", matchId, "records", "$id"]);
  }

  Future<List<MatchRecord>> getMatchRecords(
      String gameId, String matchId) async {
    return fm.getValues((map) => MatchRecord.fromMap(map),
        ["games", gameId, "matches", matchId, "records"]);
  }

  Future addMatchRecord(String game, String gameId, String matchId,
      List<Playing> playing, int id) async {
    if (playing.isNotEmpty) {
      MatchRecord record = MatchRecord(
        id: id,
        game: game,
        time_start: timeNow,
        time_end: "",
        duration: 0,
        player1Score: 0,
        player2Score: playing.second != null ? 0 : null,
        player3Score: playing.third != null ? 0 : null,
        player4Score: playing.fourth != null ? 0 : null,
      );
      await fm.setValue(["games", gameId, "matches", matchId, "records", "$id"],
          value: record.toMap().removeNull());
    }
  }

  Future updateMatchRecord(
      String gameId, String matchId, int playerIndex, int id, int score) async {
    String player = "player${playerIndex + 1}Score";
    await fm.setValue(["games", gameId, "matches", matchId, "records", "$id"],
        value: {player: score}, update: true);
  }
  //Bat Ball

  Future setBatBallDetails(String gameId,
      [BatBallDetails? details, BatBallDetails? prevDetails]) async {
    Map<String, dynamic> map = {};
    if (details != null) {
      if (details == prevDetails) await removeGameDetails(gameId);
      map = details.toMap();
      return fm.setValue(["games", gameId, "details"], value: map);
    }
  }

  Stream<BatBallDetails?> getBatBallDetails(String gameId) async* {
    yield* fm.getStreamValue(
        (map) => BatBallDetails.fromMap(map), ["games", gameId, "details"]);
  }

  //Chess
  Future setChessDetails(String gameId,
      [ChessDetails? details, ChessDetails? prevDetails]) async {
    Map<String, dynamic> map = {};
    if (details != null) {
      if (details == prevDetails) await removeGameDetails(gameId);
      map = details.toMap();
      return fm.setValue(["games", gameId, "details"], value: map);
    }
  }

  Stream<ChessDetails?> getChessDetails(String gameId) async* {
    yield* fm.getStreamValue(
        (map) => ChessDetails.fromMap(map), ["games", gameId, "details"]);
  }

  //Draught
  Future setDraughtDetails(String gameId,
      [DraughtDetails? details, DraughtDetails? prevDetails]) async {
    Map<String, dynamic> map = {};
    if (details != null) {
      if (details == prevDetails) await removeGameDetails(gameId);
      map = details.toMap();
      return fm.setValue(["games", gameId, "details"], value: map);
    }
  }

  Stream<DraughtDetails?> getDraughtDetails(String gameId) async* {
    yield* fm.getStreamValue(
        (map) => DraughtDetails.fromMap(map), ["games", gameId, "details"]);
  }

  //XandO

  Future setXandODetails(String gameId,
      [XandODetails? details, XandODetails? prevDetails]) async {
    Map<String, dynamic> map = {};
    if (details != null) {
      if (details == prevDetails) await removeGameDetails(gameId);
      map = details.toMap();
      return fm.setValue(["games", gameId, "details"], value: map);
    }
  }

  Stream<XandODetails?> getXandODetails(String gameId) async* {
    yield* fm.getStreamValue(
        (map) => XandODetails.fromMap(map), ["games", gameId, "details"]);
  }

  //Whot
  Future setWhotDetails(String gameId,
      [WhotDetails? details, WhotDetails? prevDetails]) async {
    Map<String, dynamic> map = {};
    if (details != null) {
      if (details == prevDetails) await removeGameDetails(gameId);
      map = details.toMap();
    } else {
      map = WhotDetails(
        whotIndices: getRandomIndex(54).join(","),
        currentPlayerId: "",
        playPos: -1,
        shapeNeeded: -1,
      ).toMap();
    }
    return fm.setValue(["games", gameId, "details"], value: map);
  }

  Stream<WhotDetails?> getWhotDetails(String gameId) async* {
    yield* fm.getStreamValue(
        (map) => WhotDetails.fromMap(map), ["games", gameId, "details"]);
  }

  Future<String> getWhotIndices(String gameId) async {
    final details = await (fm.getValue(
        (map) => WhotDetails.fromMap(map), ["games", gameId, "details"]));
    return details?.whotIndices ?? "";
  }

  //Ludo
  Future setLudoDetails(String gameId,
      [LudoDetails? details, LudoDetails? prevDetails]) async {
    Map<String, dynamic> map = {};
    if (details != null) {
      if (details == prevDetails) await removeGameDetails(gameId);
      map = details.toMap();
    } else {
      map = LudoDetails(
        ludoIndices: getRandomIndex(4).join(","),
        currentPlayerId: "",
        playPos: -1,
        playHouseIndex: -1,
        dice1: -1,
        dice2: -1,
        selectedFromHouse: false,
        enteredHouse: false,
      ).toMap();
    }
    return fm.setValue(["games", gameId, "details"], value: map);
  }

  Stream<LudoDetails?> getLudoDetails(String gameId) async* {
    yield* fm.getStreamValue(
        (map) => LudoDetails.fromMap(map), ["games", gameId, "details"]);
  }

  Future<String> getLudoIndices(String gameId) async {
    final details = await (fm.getValue(
        (map) => LudoDetails.fromMap(map), ["games", gameId, "details"]));
    return details?.ludoIndices ?? "";
  }

  Future removeGameDetails(String gameId) async {
    return fm.removeValue(["games", gameId, "details"]);
  }

  Stream<GameRequest?> getGameRequest() async* {
    yield* fm.getStreamValue(
        (map) => GameRequest.fromMap(map), ["users", myId, "game"]);
  }

  Future<GameRequest?> checkGameRequest(String id) async {
    return fm
        .getValue((map) => GameRequest.fromMap(map), ["users", id, "game"]);
  }

  Future<List<Playing>> getPlaying(String gameId) async {
    return fm
        .getValues((map) => Playing.fromMap(map), ["games", gameId, "playing"]);
  }

  Stream<List<Playing>> readPlaying(String gameId) async* {
    yield* fm.getStreamValues(
        (map) => Playing.fromMap(map), ["games", gameId, "playing"]);
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
    yield* fm.getStreamValues(
        (map) => Match.fromMap(map), ["games", gameId, "matches"]);
  }

  Stream<List<GameList>> readGameLists() async* {
    yield* fm.getStreamValues(
        (map) => GameList.fromMap(map), ["users", myId, "gamelist"]);
  }

  Future<List<GameList>> readGames() async {
    return fm
        .getValues((map) => GameList.fromMap(map), ["users", myId, "gamelist"]);
  }

  Future<List<Match>> readGameMatches(String id) async {
    return fm.getValues((map) => Match.fromMap(map), ["games", id, "matches"]);
  }

  void updatePresence() {
    final connref = fm.database.ref(".info/connected");
    connref.onValue.listen((event) async {
      final connected = event.snapshot.value as bool? ?? false;
      final user = fm.auth.currentUser;
      if (user != null) {
        final userId = user.uid;
        if (connected) {
          await fm.setValue(["users", userId],
              value: {"last_seen": ""}, update: true);
        } else {
          await fm.setValue([
            "users",
            userId
          ], value: {
            "last_seen": DateTime.now().millisecondsSinceEpoch.toString()
          }, update: true, withOndisconnect: true);
        }
      }
    });
  }

  String getCommonId(String id1, String id2) {
    String id = "";
    if (id1.greaterThan(id2)) {
      id = "${id1.substring(0, 14)}${id2.substring(0, 14)}";
    } else {
      id = "${id2.substring(0, 14)}${id1.substring(0, 14)}";
    }
    return id;
  }

  String getOneOnOneGameId(String opponentId) {
    String id = "";
    if (myId.greaterThan(opponentId)) {
      id = "${myId.substring(0, 14)}${opponentId.substring(0, 14)}";
    } else {
      id = "${opponentId.substring(0, 14)}${myId.substring(0, 14)}";
    }
    return id;
  }

  String getPlayersString(String opponentId) {
    String players = "";
    if (myId.greaterThan(opponentId)) {
      players = "$myId,$opponentId";
    } else {
      players = "$opponentId,$myId";
    }
    return players;
  }

  String getScoreString(String opponentId, int player1, int player2) {
    String score = "";
    if (myId.greaterThan(opponentId)) {
      score = "$player1,$player2";
    } else {
      score = "$player2,$player1";
    }
    return score;
  }
}
