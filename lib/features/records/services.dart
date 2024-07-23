import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';

import '../../core/firebase/firestore_methods.dart';
import '../../shared/utils/utils.dart';
import '../game/models/playing.dart';
import 'models/match_record.dart';

FirestoreMethods fm = FirestoreMethods();

Future<MatchRecord?> getMatchRecord(
    String gameId, String matchId, int id) async {
  return fm.getValue((map) => MatchRecord.fromMap(map),
      ["games", gameId, "matches", matchId, "records", "$id"]);
}

Future<List<MatchRecord>> getMatchRecords(
  String gameId,
  String matchId, {
  String? lastTime,
}) async {
  return fm.getValues((map) => MatchRecord.fromMap(map),
      ["games", gameId, "matches", matchId, "records"],
      order: ["time_start", true], limit: [10], start: [lastTime, true]);
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
  await fm.updateValue(["games", gameId, "matches", matchId, "records", "$id"],
      value: {player: score});
}
