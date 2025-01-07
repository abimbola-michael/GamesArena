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

Future<List<Match>> getPlayedMatches(String gameId,
    {String? type, String? lastTime, int limit = 10}) async {
  return fm.getValues(
    (map) => Match.fromMap(map),
    ["games", gameId, "matches"],
    where: [
      if (type != null) ...[
        "outcome",
        "==",
        type == "loss" ? "win" : type,
        type == "win" ? "winners" : "others",
        "contains",
        myId,
      ] else ...[
        "outcome",
        "!=",
        "",
        "players",
        "contains",
        myId,
      ],
      if (lastTime != null) ...["time_created", "<", lastTime]
    ],
    order: ["time_created", true],
    limit: [limit],
    //start: lastTime == null ? [] : [lastTime, true],
  );
}

Future<GameStat> getGameStats(String gameId, int? playersCount) async {
  int allMatches = await fm.getSnapshotCount(["games", gameId, "matches"]);
  int players =
      playersCount ?? await fm.getSnapshotCount(["games", gameId, "players"]);

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
      losses: losses);
}

// Future<GameStat> getGameStats(String gameId, int? playersCount) async {
//   int allMatches = await fm.getSnapshotCount(["games", gameId, "matches"]);
//   int players =
//       playersCount ?? await fm.getSnapshotCount(["games", gameId, "players"]);

//   int playedMatches = await fm.getSnapshotCount([
//     "games",
//     gameId,
//     "matches"
//   ], where: [
//     "players",
//     "contains",
//     myId,
//     "outcome",
//     "!=",
//     "",
//     "outcome",
//     "!=",
//     null,
//   ]);

//   int wins = await fm.getSnapshotCount([
//     "games",
//     gameId,
//     "matches"
//   ], where: [
//     "players",
//     "contains",
//     myId,
//     "outcome",
//     "==",
//     "win",
//     "winners",
//     "contains",
//     myId
//   ]);

//   // int losses = await fm.getSnapshotCount([
//   //   "games",
//   //   gameId,
//   //   "matches"
//   // ], where: [
//   //   "players",
//   //   "contains",
//   //   myId,
//   //   "outcome",
//   //   "==",
//   //   "win",
//   //   "winner",
//   //   "!=",
//   //   myId
//   // ]);

//   int draws = await fm.getSnapshotCount([
//     "games",
//     gameId,
//     "matches"
//   ], where: [
//     "players",
//     "contains",
//     myId,
//     "outcome",
//     "==",
//     "draw",
//   ]);
//   //int playedMatches = wins + ties + losses + draws;
//   int losses = playedMatches - (wins + draws);
//   return GameStat(
//       allMatches: allMatches,
//       playedMatches: playedMatches,
//       players: players,
//       wins: wins,
//       draws: draws,
//       losses: losses);
// }
