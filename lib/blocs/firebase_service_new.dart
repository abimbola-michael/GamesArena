// import 'package:gamesarena/blocs/firebase_methods.dart';
// import 'package:gamesarena/extensions/extensions.dart';
// import 'package:fluttertoast/fluttertoast.dart';

// import '../models/games/batball.dart';
// import '../models/games/chess.dart';
// import '../models/games/draught.dart';
// import '../models/games/ludo.dart';
// import '../models/games/whot.dart';
// import '../models/games/xando.dart';
// import '../models/models.dart';
// import '../models/player.dart';
// import '../utils/utils.dart';

// class FirebaseService {
//   FirebaseMethods fm = FirebaseMethods();
//   String myId = "";
//   String timeNow = DateTime.now().millisecondsSinceEpoch.toString();

//   FirebaseService() {
//     myId = fm.myId;
//   }
//   String getId(List<String> path) {
//     return fm.getId(path);
//   }

//   Future updateUserDetails(String type, String value) async {
//     return fm.setValue(["users", myId], value: {type: value}, update: true);
//   }

//   Future createUser(User user) async {
//     await fm.setValue(["users", user.user_id], value: user.toMap());
//   }

//   Future creatGroup(Group group, List<String> players) async {
//     String groupId = group.group_id;
//     players.insert(0, myId);
//     await fm.setValue(["groups", groupId], value: group.toMap());

//     if (players.isNotEmpty) {
//       for (var id in players) {
//         final player = Player(id: id, time: timeNow);
//         await fm.setValue(["groups", groupId, "players", id],
//             value: player.toMap());
//       }
//     }
//   }

//   Future<List<Player>> readPlayers() async {
//     return fm
//         .getValues((map) => Player.fromMap(map), ["users", myId, "players"]);
//   }

//   Future<List<Player>> readGroupPlayers(String groupId) async {
//     return fm.getValues(
//         (map) => Player.fromMap(map), ["groups", groupId, "players"]);
//   }

//   Stream<User?> getStreamUser(String userId) async* {
//     yield* fm
//         .getStreamValue<User>((map) => User.fromMap(map), ["users", userId]);
//   }

//   Future<User?> getUser(String userId) async {
//     return fm.getValue<User>((map) => User.fromMap(map), ["users", userId]);
//   }

//   Stream<Group?> getStreamGroup(String groupId) async* {
//     yield* fm.getStreamValue<Group>(
//         (map) => Group.fromMap(map), ["groups", groupId]);
//   }

//   Future<Group?> getGroup(String groupId) async {
//     return fm.getValue<Group>((map) => Group.fromMap(map), ["groups", groupId]);
//   }

//   Future<User?> searchUser(String type, String searchString) async {
//     final users = await fm.getValues<User>(
//         (map) => User.fromMap(map), ["users"],
//         where: [type, "==", searchString.toLowerCase().trim()]);
//     return users.isNotEmpty ? users.first : null;
//   }

//   Future<Group?> searchGroup(String type, String searchString) async {
//     final groups = await fm.getValues<Group>(
//         (map) => Group.fromMap(map), ["groups"],
//         where: [type, "==", searchString]);
//     return groups.isNotEmpty ? groups.first : null;
//   }

//   Future<List<User>> playersToUsers(List<String> players) async {
//     List<User> users = [];
//     if (players.isNotEmpty) {
//       for (var player in players) {
//         final user = await getUser(player);
//         if (user != null) users.add(user);
//       }
//     }
//     return users;
//   }

//   Future<List<User?>> playingToUsers(List<Playing> playing) async {
//     List<User?> users = [];
//     if (playing.isNotEmpty) {
//       for (var player in playing) {
//         final user = await getUser(player.id);
//         users.add(user);
//       }
//     }
//     return users;
//   }

//   Future<Game?> getGameFromPlayers(String playersString) async {
//     List<String> playerIds = playersString.contains(",")
//         ? playersString.split(",")
//         : [playersString];
//     if (!playerIds.contains(myId)) {
//       playerIds.insert(0, myId);
//     }
//     String gameId = getGameId(playerIds);
//     final game =
//         await fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
//     return game;
//   }

//   Future<List<User>> getPlayersFromGame(String gameId) async {
//     final game =
//         await fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
//     if (game == null) return [];
//     final players = game.players;
//     final playerIds = players.split(",");
//     return playersToUsers(playerIds);
//   }

//   String getGameId(List<String> players) {
//     players.sort(((a, b) => a.compareTo(b)));
//     int totalIdscount = 24;
//     int splitSize = totalIdscount ~/ players.length;
//     String id = "";
//     for (int i = 0; i < players.length; i++) {
//       final player = players[i];
//       id += player.substring(player.length - splitSize);
//     }
//     return id;
//   }

//   Future<GameRequest?> createGame(
//       String gameName, String groupId, List<String> playerIds) async {
//     String time = DateTime.now().millisecondsSinceEpoch.toString();

//     if (playerIds.length < 2) {
//       Fluttertoast.showToast(msg: "Can't create game for only one user");
//       return null;
//     }
//     playerIds.sort(((a, b) => a.compareTo(b)));

//     String gameId = getGameId(playerIds);
//     final game =
//         await fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
//     if (game == null) {
//       String players = playerIds.join(",");
//       Game game = Game(players: players, game_id: gameId, time: time);
//       await fm.setValue(["games", gameId], value: game.toMap());
//     }

//     List<int> orders = List.generate(playerIds.length, (index) => index + 1);
//     orders.shuffle();
//     List<Playing> playingList = [];
//     for (int i = 0; i < playerIds.length; i++) {
//       String playerId = playerIds[i];
//       final order = orders[i];
//       final playing = Playing(
//         id: playerId,
//         action: "pause",
//         game: gameName,
//         accept: playerId == myId,
//         order: order,
//       );
//       playingList.add(playing);
//     }

//     playingList.sortList((value) => value.order, false);

//     String matchId = fm.getId(["games", gameId, "matches"]);
//     final match = Match(
//       match_id: matchId,
//       creator_id: myId,
//       time_created: time,
//       game: gameName,
//       player1: playingList.first.id,
//       player2: playingList.second?.id,
//       player3: playingList.third?.id,
//       player4: playingList.fourth?.id,
//     );
//     await fm.setValue(["games", gameId, "matches", matchId],
//         value: match.toMap().removeNull());

//     final result = await createGameDetails(gameName, gameId, matchId);

//     if (groupId != "") {
//       await fm.setValue(["groups", groupId, "matches", matchId],
//           value: {"game_id": gameId, "match_id": matchId});
//     }
//     GameRequest request = GameRequest(
//       game_id: gameId,
//       match_id: matchId,
//       game: gameName,
//       group_id: groupId,
//       creator_id: myId,
//     );
//     int playingCount = 0;

//     for (int i = 0; i < playingList.length; i++) {
//       final playing = playingList[i];
//       String playerId = playing.id;
//       await fm.setValue(["games", gameId, "playing", playerId],
//           value: playing.toMap());
//       playingCount++;
//     }
//     // Fluttertoast.showToast(msg: "playingCount = $playingCount");

//     for (int i = 0; i < playingList.length; i++) {
//       final playing = playingList[i];
//       String playerId = playing.id;
//       await fm.setValue(["users", playerId, "game"], value: request.toMap());
//       await fm.setValue(["users", playerId, "gamelist", gameId],
//           value: GameList(game_id: gameId, time: time).toMap());
//       if (playerId != myId) {
//         await fm.setValue(["users", myId, "players", playerId],
//             value: Player(id: playerId, time: time).toMap());
//         await fm.setValue(["users", playerId, "players", myId],
//             value: Player(id: myId, time: time).toMap());
//       }
//     }
//     String indices = "";
//     if (result != null) {
//       indices = gameName == "Ludo"
//           ? (result as LudoDetails?)?.ludoIndices ?? ""
//           : gameName == "Whot"
//               ? (result as WhotDetails?)?.whotIndices ?? ""
//               : "";
//     }
//     request.playing = playingList;
//     request.indices = indices;
//     return request;
//   }

//   Future createGameDetails(String game, String gameId, String matchId) async {
//     if (game == "Chess") {
//       return setChessDetails(gameId, matchId);
//     } else if (game == "Draught") {
//       return setDraughtDetails(gameId, matchId);
//     } else if (game == "Bat Ball") {
//       return setBatBallDetails(gameId, matchId);
//     } else if (game == "X and O") {
//       return setXandODetails(gameId, matchId);
//     } else if (game == "Whot") {
//       return setWhotDetails(gameId, matchId);
//     } else if (game == "Ludo") {
//       return setLudoDetails(gameId, matchId);
//     }
//   }

//   Future cancelGame(
//       String gameId, String matchId, List<Playing> playing) async {
//     await fm.removeValue(["games", gameId, "playing"]);
//     await fm.removeValue(["games", gameId, "matches", matchId, "details"]);
//     for (var player in playing) {
//       await fm.removeValue(["users", player.id, "game"]);
//     }
//   }

//   Future joinGame(String gameId, String matchId) async {
//     await fm.setValue(["games", gameId, "playing", myId],
//         value: {"accept": true, "time": timeNow}, update: true);
//   }

//   Future leaveGame(String gameId, String matchId, List<Playing> playing,
//       bool started) async {
//     await fm.removeValue(["users", myId, "game"]);
//     await fm.removeValue(["games", gameId, "playing", myId]);
//     if (playing.length == 1) {
//       final id = playing.first.id;
//       await fm.removeValue(["users", id, "game"]);
//     }
//     if (started) {
//       if (playing.length == 1) {
//         await fm.removeValue(["games", gameId, "matches", matchId, "details"]);
//         await fm.setValue(["games", gameId, "matches", matchId],
//             value: {"time_end": timeNow}, update: true);
//       }
//     }
//   }

//   Future startGame(String game, String gameId, String matchId,
//       List<Playing> playing, int id, bool started) async {
//     await fm.setValue(["games", gameId, "playing", myId],
//         value: {"action": "start", "game": game}, update: true);
//     if (!started) {
//       final unstartedPlayers =
//           playing.where((element) => element.action != "start");
//       if (unstartedPlayers.length == 1) {
//         addMatchRecord(game, gameId, matchId, playing, id);
//         if (id == 0) {
//           await fm.setValue(["games", gameId, "matches", matchId],
//               value: {"time_start": timeNow}, update: true);
//         }
//       }
//     }
//   }

//   Future restartGame(String game, String gameId, String matchId,
//       List<Playing> playing, int id) async {
//     await fm.setValue(["games", gameId, "playing", myId],
//         value: {"action": "restart", "game": game}, update: true);

//     final unrestartedPlayers =
//         playing.where((element) => element.action != "restart");
//     if (unrestartedPlayers.length == 1) {
//       await fm.setValue(["games", gameId, "matches", matchId, "records", "$id"],
//           value: {"time_end": timeNow});

//       addMatchRecord(game, gameId, matchId, playing, id + 1);
//     }
//   }

//   Future changeGame(
//       String game, String gameId, String matchId, List<Playing> playing) async {
//     final gamePlayers = playing.where((element) => element.game != game);
//     if (gamePlayers.length == 1) {
//       await createGameDetails(game, gameId, matchId);
//     }
//     await fm.setValue(["games", gameId, "playing", myId],
//         value: {"game": game}, update: true);
//   }

//   Future pauseGame(String gameId, String matchId, List<Playing> playing) async {
//     if (playing.isNotEmpty) {
//       for (var player in playing) {
//         await fm.setValue(["games", gameId, "playing", player.id],
//             value: {"action": "pause"}, update: true);
//       }
//     }
//   }

//   Future<MatchRecord?> getMatchRecord(
//       String gameId, String matchId, int id) async {
//     return fm.getValue((map) => MatchRecord.fromMap(map),
//         ["games", gameId, "matches", matchId, "records", "$id"]);
//   }

//   Future<List<MatchRecord>> getMatchRecords(
//       String gameId, String matchId) async {
//     return fm.getValues((map) => MatchRecord.fromMap(map),
//         ["games", gameId, "matches", matchId, "records"]);
//   }

//   Future addMatchRecord(String game, String gameId, String matchId,
//       List<Playing> playing, int id) async {
//     if (playing.isNotEmpty) {
//       MatchRecord record = MatchRecord(
//         id: id,
//         game: game,
//         time_start: timeNow,
//         time_end: "",
//         player1Score: 0,
//         player2Score: playing.second != null ? 0 : null,
//         player3Score: playing.third != null ? 0 : null,
//         player4Score: playing.fourth != null ? 0 : null,
//       );
//       await fm.setValue(["games", gameId, "matches", matchId, "records", "$id"],
//           value: record.toMap().removeNull());
//     }
//   }

//   Future updateMatchRecord(
//       String gameId, String matchId, int playerIndex, int id, int score) async {
//     String player = "player${playerIndex + 1}Score";
//     await fm.setValue(["games", gameId, "matches", matchId, "records", "$id"],
//         value: {player: score}, update: true);
//   }
//   //Bat Ball

//   Future setBatBallDetails(String gameId, String matchId,
//       [BatBallDetails? details]) async {
//     Map<String, dynamic> map = {};
//     if (details != null) {
//       map = details.toMap();
//       return fm.setValue(["games", gameId, "matches", matchId, "details"],
//           value: map.removeNull(), update: true);
//     } else {
//       // map = BatBallDetails(
//       //   angle: Random().nextInt(91),
//       //   // hDir: Random().nextInt(2) == 0 ? "left" : "right",
//       //   // vDir: Random().nextInt(2) == 0 ? "up" : "down",
//       // ).toMap();
//     }
//   }

//   Stream<BatBallDetails?> getBatBallDetails(
//       String gameId, String matchId) async* {
//     yield* fm.getStreamValue((map) => BatBallDetails.fromMap(map),
//         ["games", gameId, "matches", matchId, "details"]);
//   }

//   //Chess
//   Future setChessDetails(String gameId, String matchId,
//       [ChessDetails? details]) async {
//     Map<String, dynamic> map = {};
//     if (details != null) {
//       map = details.toMap();
//       return fm.setValue(["games", gameId, "matches", matchId, "details"],
//           value: map.removeNull(), update: true);
//     } else {
//       // map = ChessDetails(
//       //         //currentPlayerId: myId,
//       //         )
//       //     .toMap();
//     }
//   }

//   Stream<ChessDetails?> getChessDetails(String gameId, String matchId) async* {
//     yield* fm.getStreamValue((map) => ChessDetails.fromMap(map),
//         ["games", gameId, "matches", matchId, "details"]);
//   }

//   //Draught
//   Future setDraughtDetails(String gameId, String matchId,
//       [DraughtDetails? details]) async {
//     Map<String, dynamic> map = {};
//     if (details != null) {
//       map = details.toMap();
//       return fm.setValue(["games", gameId, "matches", matchId, "details"],
//           value: map.removeNull(), update: true);
//     } else {
//       // map = DraughtDetails(
//       //         //currentPlayerId: myId,
//       //         )
//       //     .toMap();
//     }
//   }

//   Stream<DraughtDetails?> getDraughtDetails(
//       String gameId, String matchId) async* {
//     yield* fm.getStreamValue((map) => DraughtDetails.fromMap(map),
//         ["games", gameId, "matches", matchId, "details"]);
//   }

//   //XandO

//   Future setXandODetails(String gameId, String matchId,
//       [XandODetails? details]) async {
//     Map<String, dynamic> map = {};
//     if (details != null) {
//       map = details.toMap();
//       return fm.setValue(["games", gameId, "matches", matchId, "details"],
//           value: map.removeNull(), update: true);
//     } else {
//       // map = XandODetails(
//       //         //currentPlayerId: myId,
//       //         )
//       //     .toMap();
//     }
//   }

//   Stream<XandODetails?> getXandODetails(String gameId, String matchId) async* {
//     yield* fm.getStreamValue((map) => XandODetails.fromMap(map),
//         ["games", gameId, "matches", matchId, "details"]);
//   }

//   //Whot

//   Future setWhotDetails(String gameId, String matchId,
//       [WhotDetails? details]) async {
//     Map<String, dynamic> map = {};
//     if (details != null) {
//       map = details.toMap();
//     } else {
//       map = WhotDetails(
//         whotIndices: getRandomIndex(54).join(","),
//         //currentPlayerId: myId,
//       ).toMap();
//     }
//     return fm.setValue(["games", gameId, "matches", matchId, "details"],
//         value: map.removeNull(), update: details != null);
//   }

//   Stream<WhotDetails?> getWhotDetails(String gameId, String matchId) async* {
//     yield* fm.getStreamValue((map) => WhotDetails.fromMap(map),
//         ["games", gameId, "matches", matchId, "details"]);
//   }

//   Future<String> getWhotIndices(String gameId, String matchId) async {
//     final details = await (fm.getValue((map) => WhotDetails.fromMap(map),
//         ["games", gameId, "matches", matchId, "details"]));
//     return details?.whotIndices ?? "";
//   }

//   //Ludo
//   Future setLudoDetails(String gameId, String matchId,
//       [LudoDetails? details]) async {
//     Map<String, dynamic> map = {};
//     if (details != null) {
//       map = details.toMap();
//     } else {
//       map = LudoDetails(
//         ludoIndices: getRandomIndex(4).join(","),
//         //currentPlayerId: myId,
//       ).toMap();
//     }
//     return fm.setValue(["games", gameId, "matches", matchId, "details"],
//         value: map.removeNull(), update: details != null);
//   }

//   Stream<LudoDetails?> getLudoDetails(String gameId, String matchId) async* {
//     yield* fm.getStreamValue((map) => LudoDetails.fromMap(map),
//         ["games", gameId, "matches", matchId, "details"]);
//   }

//   Future<String> getLudoIndices(String gameId, String matchId) async {
//     final details = await (fm.getValue((map) => LudoDetails.fromMap(map),
//         ["games", gameId, "matches", matchId, "details"]));
//     return details?.ludoIndices ?? "";
//   }

//   Stream<GameRequest?> getGameRequest() async* {
//     yield* fm.getStreamValue(
//         (map) => GameRequest.fromMap(map), ["users", myId, "game"]);
//   }

//   Future<GameRequest?> checkGameRequest(String id) async {
//     return fm
//         .getValue((map) => GameRequest.fromMap(map), ["users", id, "game"]);
//   }

//   Future<List<Playing>> getPlaying(String gameId) async {
//     return fm
//         .getValues((map) => Playing.fromMap(map), ["games", gameId, "playing"]);
//   }

//   Stream<List<Playing>> readPlaying(String gameId) async* {
//     yield* fm.getStreamValues(
//         (map) => Playing.fromMap(map), ["games", gameId, "playing"]);
//   }

//   Future<Game?> getGame(String gameId) async {
//     return fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
//   }

//   Future<Match?> getLastMatch(String gameId) async {
//     final matches = await fm
//         .getValues((map) => Match.fromMap(map), ["games", gameId, "matches"]);
//     return matches.isNotEmpty ? matches.last : null;
//   }

//   Future<Match?> getMatch(String gameId, String matchId) async {
//     return fm.getValue(
//         (map) => Match.fromMap(map), ["games", gameId, "matches", matchId]);
//   }

//   Future<List<Match>> getMatches(String gameId) async {
//     return fm
//         .getValues((map) => Match.fromMap(map), ["games", gameId, "matches"]);
//   }

//   Stream<List<Match>> getMatchesStream(String gameId) async* {
//     yield* fm.getStreamValues(
//         (map) => Match.fromMap(map), ["games", gameId, "matches"]);
//   }

//   // Future<MatchRecord?> getMatchRecords(String game_id, String match_id) async {
//   //   return fm.getValue((map) => MatchRecord.fromMap(map),
//   //       ["games", game_id, "matches", match_id, "records"]);
//   // }

//   // Stream<List<MatchRecord>> getMatchRecordsStream(
//   //     String game_id, String match_id) async* {
//   //   yield* fm.getStreamValues((map) => MatchRecord.fromMap(map),
//   //       ["games", game_id, "matches", match_id, "records"]);
//   // }

//   Stream<List<GameList>> readGameLists() async* {
//     yield* fm.getStreamValues(
//         (map) => GameList.fromMap(map), ["users", myId, "gamelist"]);
//   }

//   Future<List<GameList>> readGames() async {
//     return fm
//         .getValues((map) => GameList.fromMap(map), ["users", myId, "gamelist"]);
//   }

//   // Stream<List<Match>> readMatches() async* {
//   //   yield* fm.getStreamValues(
//   //       (map) => Match.fromMap(map), ["users", myId, "matches"]);
//   // }

//   // Stream<List<Match>> readGroupMatches(String group_id) async* {
//   //   yield* fm.getStreamValues(
//   //       (map) => Match.fromMap(map), ["groups", group_id, "matches"]);
//   // }

//   Future<List<Match>> readGameMatches(String id) async {
//     return fm.getValues((map) => Match.fromMap(map), ["games", id, "matches"]);
//   }

//   void updatePresence() {
//     final connref = fm.database.ref(".info/connected");
//     connref.onValue.listen((event) async {
//       final connected = event.snapshot.value as bool? ?? false;
//       if (myId != "") {
//         if (connected) {
//           //Fluttertoast.showToast(msg: "Connected");
//           await fm.setValue(["users", myId],
//               value: {"last_seen": ""}, update: true, withOndisconnect: true);
//         } else {
//           await fm.setValue(["users", myId],
//               value: {"last_seen": timeNow},
//               update: true,
//               withOndisconnect: true);
//           //Fluttertoast.showToast(msg: "DisConnected");
//         }
//       }
//     });
//   }

//   String getCommonId(String id1, String id2) {
//     String id = "";
//     if (id1.greaterThan(id2)) {
//       id = "${id1.substring(0, 14)}${id2.substring(0, 14)}";
//     } else {
//       id = "${id2.substring(0, 14)}${id1.substring(0, 14)}";
//     }
//     return id;
//   }

//   String getOneOnOneGameId(String opponentId) {
//     String id = "";
//     if (myId.greaterThan(opponentId)) {
//       id = "${myId.substring(0, 14)}${opponentId.substring(0, 14)}";
//     } else {
//       id = "${opponentId.substring(0, 14)}${myId.substring(0, 14)}";
//     }
//     return id;
//   }

//   String getPlayersString(String opponentId) {
//     String players = "";
//     if (myId.greaterThan(opponentId)) {
//       players = "$myId,$opponentId";
//     } else {
//       players = "$opponentId,$myId";
//     }
//     return players;
//   }

//   String getScoreString(String opponentId, int player1, int player2) {
//     String score = "";
//     if (myId.greaterThan(opponentId)) {
//       score = "$player1,$player2";
//     } else {
//       score = "$player2,$player1";
//     }
//     return score;
//   }
// }
