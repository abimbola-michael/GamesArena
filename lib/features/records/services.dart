import 'package:gamesarena/shared/models/models.dart';
import 'package:gamesarena/shared/utils/utils.dart';

import '../../core/firebase/firestore_methods.dart';
import 'models/game_stat.dart';

FirestoreMethods fm = FirestoreMethods();
Future<Player?> getPlayer(String gameId, String playerId) {
  return fm.getValue(
      (map) => Player.fromMap(map), ["games", gameId, "players", playerId]);
}

Future<List<Player>> getGamePlayers(Game game,
    {String? role, String? lastTime, int limit = 10}) async {
  final gameId = game.game_id;
  //final creatorId = game.creatorId;
  return fm.getValues(
    (map) => Player.fromMap(map), ["games", gameId, "players"],
    where: [
      ...["id", "!=", myId],
      if (role != null) ...["role", "==", role],
      if (lastTime != null) ...["time", ">", lastTime]
    ],
    order: ["time", false],
    limit: [limit],
    //start: lastTime == null ? [] : [lastTime, true]
  );
}

List<dynamic> getPlayedMatchesQueries(String type) {
  return [
    if (type == "missed") ...[
      "players",
      "contains",
      myId,
      "outcome",
      "==",
      "",
    ] else if (type == "incomplete") ...[
      "players",
      "contains",
      myId,
      "time_start",
      "null",
      false,
      "time_end",
      "null",
      true,
    ] else if (type == "play") ...[
      "outcome",
      "!=",
      "",
      "players",
      "contains",
      myId,
    ] else ...[
      "outcome",
      "==",
      type == "loss" ? "win" : type,
      type == "win" ? "winners" : "others",
      "contains",
      myId,
    ],
  ];
}

Future<List<Match>> getPlayedMatches(String gameId,
    {required String type, String? lastTime, int limit = 10}) async {
  return fm.getValues(
    (map) => Match.fromMap(map),
    ["games", gameId, "matches"],
    where: [
      ...getPlayedMatchesQueries(type),
      if (lastTime != null) ...["time_created", "<", lastTime]
    ],
    order: ["time_created", true],
    limit: [limit],
    //start: lastTime == null ? [] : [lastTime, true],
  );
}

Future<int> getPlayedMatchesCount(String gameId, String type) async {
  return fm.getSnapshotCount(["games", gameId, "matches"],
      where: type.isEmpty ? [] : getPlayedMatchesQueries(type));
}

Future<int> getPlayersCount(String gameId) async {
  return fm.getSnapshotCount(["games", gameId, "players"]);
}

Future<GameStat> getGameStats(String gameId, int? playersCount) async {
  int allMatches = await fm.getSnapshotCount(["games", gameId, "matches"]);
  int players =
      playersCount ?? await fm.getSnapshotCount(["games", gameId, "players"]);

  int misseds = await fm.getSnapshotCount([
    "games",
    gameId,
    "matches"
  ], where: [
    "players",
    "contains",
    myId,
    "time_start",
    "==",
    null,
  ]);

  int incompletes = await fm.getSnapshotCount([
    "games",
    gameId,
    "matches"
  ], where: [
    "players",
    "contains",
    myId,
    "time_start",
    "!=",
    null,
    "time_end",
    "==",
    null,
    "outcome",
    "!=",
    "",
  ]);

  int playedMatches = await fm.getSnapshotCount([
    "games",
    gameId,
    "matches"
  ], where: [
    "outcome",
    "!=",
    "",
    "players",
    "contains",
    myId,
  ]);

  int wins = await fm.getSnapshotCount([
    "games",
    gameId,
    "matches"
  ], where: [
    "outcome",
    "==",
    "win",
    "winners",
    "contains",
    myId,
  ]);

  int draws = await fm.getSnapshotCount([
    "games",
    gameId,
    "matches"
  ], where: [
    "outcome",
    "==",
    "draw",
    "others",
    "contains",
    myId,
  ]);
  //int playedMatches = wins + ties + losses + draws;
  int losses = playedMatches - (wins + draws);
  return GameStat(
      allMatches: allMatches,
      playedMatches: playedMatches,
      players: players,
      wins: wins,
      draws: draws,
      losses: losses,
      incompletes: incompletes,
      misseds: misseds);
}
