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

List<int> stringOptionsToListIndex(
    List<String> gameRules, String? optionsString) {
  if ((optionsString ?? "").isEmpty) return [];
  final indices =
      optionsString!.contains(",") ? optionsString.split(",") : [optionsString];
  return indices.map((index) => int.parse(index)).toList();
}

List<String> stringOptionsToListValue(
    List<String> gameRules, String? optionsString) {
  if ((optionsString ?? "").isEmpty) return [];
  final indices =
      optionsString!.contains(",") ? optionsString.split(",") : [optionsString];
  return indices.map((index) => gameRules[int.parse(index)]).toList();
}

String listOptionsToString(
    List<String> gameRules, List<String> selectedOptions) {
  List<int> optionsIndices =
      selectedOptions.map((option) => gameRules.indexOf(option)).toList();
  optionsIndices.sortList((p0) => p0, false);
  return optionsIndices.join(",");
}

Future<dynamic> gotoGamePage(
    BuildContext context, String? game, String gameId, String matchId,
    {Match? match,
    List<User?>? users,
    List<Player>? players,
    int playersSize = 2,
    bool isComputer = false,
    String? difficultyLevel,
    bool isWatch = false,
    int? recordId,
    int? roundId,
    bool isReplacement = true,
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
  }

  final args = {
    "gameName": game ?? match?.games?.firstOrNull,
    "matchId": matchId,
    "gameId": gameId,
    "match": match,
    "users": users,
    "players": players,
    "playersSize": playersSize,
    "recordId": recordId,
    "roundId": roundId,
    "isWatch": isWatch,
    "isComputer": isComputer,
    "difficultyLevel": difficultyLevel,
  };
  if (!context.mounted) return;

  if (isReplacement) {
    return context.pushReplacementNamed(GamePage.route,
        args: args, result: result);
  } else {
    return context.pushNamedTo(GamePage.route, args: args);
  }
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

List<int> getLowestCountPlayer(List<int> playersCounts, {int? highestCount}) {
  Map<int, List<int>> map = {};
  int? lowestCount;
  for (var i = 0; i < playersCounts.length; i++) {
    final count = playersCounts[i];
    if (highestCount != null && count > highestCount) {
      continue;
    }
    if (lowestCount == null || count < lowestCount) {
      lowestCount = count;
    }
    if (map[count] != null) {
      map[count]!.add(i);
    } else {
      map[count] = [i];
    }
  }
  return lowestCount != null ? map[lowestCount]! : [];
}

List<int> getHighestCountPlayer(List<int> playersCounts, {int? lowestCount}) {
  Map<int, List<int>> map = {};
  int? highestCount;

  for (var i = 0; i < playersCounts.length; i++) {
    final count = playersCounts[i];
    if (lowestCount != null && count < lowestCount) {
      continue;
    }
    if (highestCount == null || count > highestCount) {
      highestCount = count;
    }
    if (map[count] != null) {
      map[count]!.add(i);
    } else {
      map[count] = [i];
    }
  }
  return highestCount != null ? map[highestCount]! : [];
}

String getOtherPlayersUsernames(List<User> users) {
  return users
      .where((user) => user.user_id != myId)
      .map((e) => e.username)
      .toList()
      .join(" & ");
  // .toStringWithCommaandAnd((t) => t);
}

String getAllPlayersUsernames(List<User> users) {
  return users
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

// String getMatchDuration(Match? match) {
//   if (match == null || match.time_start == null) return "";
//   if (match.time_end == null) return "live";
//   int duration = int.parse(match.time_end!) - int.parse(match.time_start!);
//   return (duration ~/ 1000).toDurationString();
// }
double getMatchDuration(Match match) {
  if (match.time_start == null || match.time_end == null) return 0;
  double duration = 0;
  for (int i = 0; i < match.records!.length; i++) {
    final record = MatchRecord.fromMap(match.records!["$i"]);
    duration += getMatchRecordDuration(record);
  }
  return duration;
}

double getMatchRecordDuration(MatchRecord record) {
  if (record.time_end == null) return 0;
  double duration = 0.0;
  for (int i = 0; i < record.rounds.length; i++) {
    final roundMap = record.rounds["$i"];
    if (roundMap != null) {
      final round = MatchRound.fromMap(roundMap);
      duration += round.duration;
    }
  }
  return duration;
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
  return messages.isEmpty
      ? ""
      : "${messages.toStringWithCommaandAnd((t) => t.capitalize)} game${games.length == 1 ? "" : "s"}";

  // return "${messages.isEmpty ? "0" : messages.toStringWithCommaandAnd((t) => t.capitalize)} game${games.length == 1 ? "" : "s"}";
}

int getPlayerOverallScore(Match match, String playerId) {
  if ((match.players ?? []).isEmpty) return -1;
  final overallOutcome = getMatchOverallOutcome(match);
  final allScores = overallOutcome.scores;
  final playerIndex = match.players!.indexWhere((id) => id == playerId);
  if (playerIndex == -1) return -1;
  return allScores[playerIndex];
}

String getOverallMatchOutcomeMessage(Match match) {
  final overallOutcome = getMatchOverallOutcome(match);
  return getMatchOutcomeMessageFromScores(
      overallOutcome.scores.toList().cast(), match.players!,
      users: match.users);
}

MatchOverallOutcome getMatchOverallOutcome(Match match) {
  List<List<String>> games =
      List.generate(match.players!.length, (index) => []);

  List<int> scores = List.generate(match.players!.length,
      (index) => match.records == null || match.records!.isEmpty ? -1 : 0);
  if (match.records == null || match.records!.isEmpty) {
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
      return "This means this record ends and a new record is started from 0 - 0 with the same game";
    case "change":
      return "This means this record ends and a new record is started from 0 - 0 with the new game";
    case "leave":
      return "This means you are out of the match and would not be added to subsequent rounds";
    case "concede":
      return "This means you accept that you have lost this round and your opponent wins";
    case "close":
      return "This means to close match, can later continue as long as there is at least 2 players left";
    case "previous":
      return "This means to go the previous round";
    case "next":
      return "This means to go the next round";
  }
  return "";
}

extension QuizExtensions on String {
  bool get isChessOrDraught => this == chessGame || this == draughtGame;
  bool get isPuzzle => allPuzzleGames.contains(this);
  bool get isQuiz => allQuizGames.contains(this) || endsWith("Quiz");
  bool get isCard => allCardGames.contains(this);
  bool get isBoard => allBoardGames.contains(this);
}
