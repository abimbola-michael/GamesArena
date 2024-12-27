import 'package:flutter/widgets.dart';
import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:gamesarena/features/game/models/match_overall_outcome.dart';
import 'package:gamesarena/features/game/services.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/constants.dart';
import '../records/models/match_round.dart';
import 'pages/game_page.dart';
import '../../shared/utils/utils.dart';
import '../records/models/match_record.dart';
import '../user/models/user.dart';
import 'models/player.dart';
import 'models/match.dart';

void gotoGamePage(
    BuildContext context, String game, String gameId, String matchId,
    {Match? match,
    List<User?>? users,
    List<Player>? players,
    int playersSize = 2,
    String? indices,
    Map<int, List<Map<String, dynamic>>?>? recordGameDetails,
    int gameDetailIndex = -1,
    bool isWatch = false,
    int recordId = 0,
    int roundId = 0,
    String? currentPlayerId,
    int adsTime = 0,
    Object? result}) async {
  if (match != null) {
    //Match prevMatch = match.copyWith();

    if (match.players == null && players != null) {
      final playerIds = players.map((e) => e.id).toList();
      match.players = playerIds;
    }

    if (match.users != null && users == null) {
      users = match.users;
    }
    users ??= await playersToUsers(match.players!);

    final playerIds = users.map((e) => e!.user_id).toList();
    currentPlayerId ??= playerIds.last;

    // updateMatchRecord(
    //     match, recordId, game, players!, isWatch, currentPlayerId);
  }

  final args = {
    "gameName": game,
    "matchId": matchId,
    "gameId": gameId,
    "match": match,
    "users": users,
    "players": players,
    "playersSize": playersSize,
    "recordId": recordId,
    "roundId": roundId,
    "indices": indices,
    "recordGameDetails": recordGameDetails,
    "gameDetailIndex": gameDetailIndex,
    "isWatch": isWatch,
    "adsTime": adsTime,
  };
  if (!context.mounted) return;
  // context.pushReplacementNamed(
  //     "/${game.endsWith("Quiz") ? "quiz" : game.replaceAll(" ", "").toLowerCase()}",
  //     args: args,
  //     result: result);

  context.pushReplacementNamed(GamePage.route, args: args, result: result);
}

// void updateMatchRecord(Match match, int recordId, String game,
//     List<Player> players, bool isWatch, String currentPlayerId) {
//   final gameId = match.game_id;
//   final matchId = match.match_id;
//   if (gameId == null || matchId == null) return;
//   Match prevMatch = match.copyWith();

//   final time = timeNow;
//   match.time_start ??= time;

//   if (match.recordsCount == null || recordId > match.recordsCount!) {
//     match.recordsCount = recordId;
//   }
//   if (match.records!["$recordId"] == null) {
//     match.records!["$recordId"] = MatchRecord(
//         id: recordId,
//         game: game,
//         time_start: time,
//         players: players.map((e) => e.id).toList(),
//         scores: List.generate(players.length, (index) => 0)
//             .toMap()
//             .map((key, value) => MapEntry(key.toString(), value)),
//         rounds: {}).toMap().removeNull();

//     final matchOutcome =
//         getMatchOutcome(getMatchOverallScores(match), match.players!);

//     match.outcome = matchOutcome.outcome;
//     match.winners = matchOutcome.winners;
//     match.others = matchOutcome.others;

//     if (gameId.isNotEmpty && !isWatch && currentPlayerId == myId) {
//       match.time_modified = time;
//       updateMatch(gameId, matchId, match,
//           prevMatch.toMap().getChangedProperties(match.toMap()));
//     }
//   }
// }

// void updateMatchRound(Match match, int recordId, int roundId, String game,
//     List<Player> players, bool isWatch, String currentPlayerId) {
//   final gameId = match.game_id;
//   final matchId = match.match_id;
//   if (gameId == null || matchId == null) return;
//   Match prevMatch = match.copyWith();

//   final time = timeNow;
//   match.time_start ??= time;

//   if (match.recordsCount == null || recordId > match.recordsCount!) {
//     match.recordsCount = recordId;
//   }
//   if (match.records!["$recordId"] == null) {
//     match.records!["$recordId"] = MatchRecord(
//         id: recordId,
//         game: game,
//         time_start: time,
//         players: players.map((e) => e.id).toList(),
//         scores: List.generate(players.length, (index) => 0)
//             .toMap()
//             .map((key, value) => MapEntry(key.toString(), value)),
//         rounds: {}).toMap().removeNull();

//     final matchOutcome =
//         getMatchOutcome(getMatchOverallScores(match), match.players!);

//     match.outcome = matchOutcome.outcome;
//     match.winners = matchOutcome.winners;
//     match.others = matchOutcome.others;

//     if (gameId.isNotEmpty && !isWatch && currentPlayerId == myId) {
//       match.time_modified = time;
//       updateMatch(gameId, matchId, match,
//           prevMatch.toMap().getChangedProperties(match.toMap()));
//     }
//   }
// }

List<int> getLowestCountPlayer(List<int> playersCounts) {
  Map<int, List<int>> map = {};
  int lowestCount = playersCounts[0];
  map[lowestCount] = [0];
  for (var i = 1; i < playersCounts.length; i++) {
    final count = playersCounts[i];
    if (count < lowestCount) {
      lowestCount = count;
    }
    if (map[count] != null) {
      map[count]!.add(i);
    } else {
      map[count] = [i];
    }
  }
  return map[lowestCount]!;
}

List<int> getHighestCountPlayer(List<int> playersCounts) {
  Map<int, List<int>> map = {};
  int highestCount = playersCounts[0];
  map[highestCount] = [0];
  for (var i = 1; i < playersCounts.length; i++) {
    final count = playersCounts[i];
    if (count > highestCount) {
      highestCount = count;
    }
    if (map[count] != null) {
      map[count]!.add(i);
    } else {
      map[count] = [i];
    }
  }
  return map[highestCount]!;
}

String getOtherPlayersUsernames(List<User> users) {
  return users
      .where((user) => user.user_id != myId)
      .map((e) => e.username)
      .toList()
      .toStringWithCommaandAnd((t) => t);
}

String getPlayersVs(List<User> users) {
  return users.map((e) => e.username).join(" vs ");
}

// String getMatchRecordMessage(Match match) {
//   final records = match.records;
//   if (records == null || records.isEmpty || match.players == null) {
//     return "Missed Match";
//   }

//   List<String> games = getgames(match);
//   List<int> scores = getMatchOverallScores(match);

//   //return "${scores.join(" - ")} . ${games.toStringWithCommaandAnd((t) => t)} . ${match.recordsCount} records";
//   return "Scores: ${scores.join(" - ")} • Games: ${games.toStringWithCommaandAnd((t) => t)} • Rounds: ${match.recordsCount} • Duration: ${getMatchDuration(match)}";
// }

String getMatchDuration(Match? match) {
  if (match == null || match.time_start == null) return "";
  if (match.time_end == null) return "live";
  int duration = int.parse(match.time_end!) - int.parse(match.time_start!);
  return (duration ~/ 1000).toDurationString();
}

List<String> getgames(Match match) {
  if (match.records == null) return [];
  List<String> games = [];
  for (int i = 0; i < match.records!.length; i++) {
    final record = MatchRecord.fromMap(match.records!["$i"]);
    if (!games.contains(record.game)) {
      games.add(record.game);
    }
  }
  return games;
}

List<MatchRecord> getMatchRecords(Match match) {
  if (match.records == null) return [];

  List<MatchRecord> records = [];
  for (int i = 0; i < match.records!.length; i++) {
    final record = MatchRecord.fromMap(match.records!["$i"]);
    records.add(record);
  }
  return records;
}

List<MatchRound> getMatchRecordRounds(MatchRecord record) {
  List<MatchRound> rounds = [];
  for (int i = 0; i < record.rounds.length; i++) {
    final round = MatchRound.fromMap(record.rounds["$i"]);
    rounds.add(round);
  }
  return rounds;
}

// List<int> getMatchOverallScores(Match match) {
//   if (match.records == null) return [];

//   List<int> scores = List.generate(match.players!.length, (index) => 0);
//   for (int i = 0; i < match.records!.length; i++) {
//     final record = MatchRecord.fromMap(match.records![(i + 1).toString()]);
//     for (int j = 0; j < record.players.length; j++) {
//       final player = record.players[j];
//       final score = record.scores["$j"];
//       final playerIndex =
//           match.players!.indexWhere((element) => element == player);
//       if (playerIndex != -1 && score != null) {
//         scores[playerIndex] += score as int;
//       }
//     }
//   }
//   return scores;
// }
// MatchRecord getMatchRecord(int recordId, Map<String, dynamic> records) {
//   final matchRoundsValue = records["$recordId"];
//   if (matchRoundsValue == null) {
//     return MatchRecord(
//         id: recordId,
//         game: "",
//         time_start: "",
//         players: [],
//         scores: {},
//         rounds: []);
//   }
//   Map<String, dynamic> matchRounds = matchRoundsValue as Map<String, dynamic>;
//   List<MatchRound> rounds = [];
//   for (int i = 0; i < matchRounds.length; i++) {
//     final round = MatchRound.fromMap(matchRounds["${i + 1}"]);
//     rounds.add(round);
//   }
//   return MatchRecord(
//       id: recordId,
//       game: rounds.firstOrNull?.game ?? "",
//       players: rounds.firstOrNull?.players ?? [],
//       time_start: rounds.firstOrNull?.time_start ?? "",
//       time_end: rounds.lastOrNull?.time_start ?? "",
//       scores: rounds.lastOrNull?.scores ?? {},
//       rounds: rounds);
// }

List<int> getMatchOverallScores(Match match) {
  //if (match.records == null) return [];

  List<int> scores = List.generate(
      match.players!.length, (index) => match.records == null ? -1 : 0);
  if (match.records == null) {
    return scores;
  }
  for (int i = 0; i < match.records!.length; i++) {
    final record = MatchRecord.fromMap(match.records!["$i"]);

    final matchOutcome =
        getMatchOutcome(record.scores.toList().cast(), record.players);
    if (matchOutcome.outcome == "win") {
      for (int i = 0; i < matchOutcome.winners.length; i++) {
        final player = matchOutcome.winners[i];
        final playerIndex =
            match.players!.indexWhere((element) => element == player);
        if (playerIndex != -1) {
          scores[playerIndex]++;
        }
      }
    }
  }
  return scores;
}

String getGamesWonMessage(List<String> games) {
  List<String> messages = [];
  Map<String, int> gamesMap = {};
  for (int i = 0; i < games.length; i++) {
    final game = games[i];
    gamesMap[game] = gamesMap[game] == null ? 1 : gamesMap[game]! + 1;
  }
  for (var entry in gamesMap.entries) {
    messages.add("${entry.value} ${entry.key}");
  }
  return "${messages.isEmpty ? "0" : messages.toStringWithCommaandAnd((t) => t.capitalize)} game${games.length == 1 ? "" : "s"}";
}

MatchOverallOutcome getMatchOverallOutcome(Match match) {
  List<List<String>> games =
      List.generate(match.players!.length, (index) => []);

  List<int> scores = List.generate(
      match.players!.length, (index) => match.records == null ? -1 : 0);
  if (match.records == null) {
    return MatchOverallOutcome(scores: scores, games: games);
  }
  for (int i = 0; i < match.records!.length; i++) {
    final record = MatchRecord.fromMap(match.records!["$i"]);

    final matchOutcome =
        getMatchOutcome(record.scores.toList().cast(), record.players);
    if (matchOutcome.outcome == "win") {
      for (int i = 0; i < matchOutcome.winners.length; i++) {
        final player = matchOutcome.winners[i];
        final playerIndex =
            match.players!.indexWhere((element) => element == player);
        if (playerIndex != -1) {
          scores[playerIndex]++;
          games[playerIndex].add(record.game);
        }
      }
    }
  }

  return MatchOverallOutcome(scores: scores, games: games);
}

List<List<int?>> getMatchOverallTotalScores(Match match) {
  if (match.records == null) return [];
  List<List<int?>> allScores = [];
  List<int> overallScores = List.generate(match.players!.length, (index) => 0);

  for (int i = 0; i < match.records!.length; i++) {
    final record = MatchRecord.fromMap(match.records!["$i"]);
    List<int?> scores = [];
    for (int j = 0; j < record.players.length; j++) {
      final player = record.players[j];
      final score = record.scores["$j"];
      final playerIndex =
          match.players!.indexWhere((element) => element == player);
      if (playerIndex != -1 && score != null) {
        scores.add(score);
        overallScores[playerIndex] += score as int;
      } else {
        scores.add(null);
      }
    }
    allScores.add(scores);
  }
  allScores.add(overallScores);
  return allScores;
}

String getMoreInfoOnComfirmation(String comfirmationType) {
  switch (comfirmationType) {
    case "restart":
      return "This means to start a new game from 0 - 0";
    case "change":
      return "This means this game ends and a new game is started";
    case "leave":
      return "This means you are out of the game";
    case "concede":
      return "This means you accept that you have lost the game and your opponent wins";
    case "previous":
      return "This means to go the previous game record";
    case "next":
      return "This means to go the next game record";
  }
  return "";
}

bool isChessOrDraught(String gameName) =>
    gameName == chessGame || gameName == draughtGame;
bool isPuzzle(String gameName) => allPuzzleGames.contains(gameName);
bool isQuiz(String gameName) => gameName.endsWith("Quiz");
bool isCard(String gameName) => allCardGames.contains(gameName);
