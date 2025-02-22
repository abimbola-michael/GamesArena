import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:gamesarena/core/firebase/firebase_notification.dart';
import 'package:gamesarena/core/firebase/firebase_methods.dart';
import 'package:gamesarena/core/firebase/firestore_methods.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import '../features/user/services.dart';
import '../main.dart';
import 'models/private_key.dart';

import 'utils/utils.dart';

FirestoreMethods fm = FirestoreMethods();

Future setGameDetails(
    String gameId, String matchId, Map<String, dynamic> map) async {
  final detailId = getId(["games", gameId, "matches", matchId, "details"]);
  return fm.setValue(["games", gameId, "matches", matchId, "details", detailId],
      value: {...map.removeNull(), "detailId": detailId});
}

Future<List<Map<String, dynamic>>> getGameDetails(
    String gameId, String matchId, int recordId, int roundId,
    {String? time,
    int? limit,
    double? duration,
    int? index,
    List<String>? players}) async {
  return fm.getValues(
      (map) => map, ["games", gameId, "matches", matchId, "details"],
      where: [
        "recordId",
        "==",
        recordId,
        "roundId",
        "==",
        roundId,
        if (players != null) ...["id", "in", players],
        if (duration != null) ...["duration", "<=", duration],
        if (index != null) ...["index", "<=", index]
      ],
      order: ["time"],
      start: time != null ? [time, true] : null,
      limit: limit != null ? [limit] : null);
}

Stream<List<ValueChange<Map<String, dynamic>>>> getGameDetailsChange(
    String gameId, String matchId, int recordId, int roundId,
    {String? time, List<String>? players}) async* {
  yield* fm.getValuesChangeStream(
      (map) => map, ["games", gameId, "matches", matchId, "details"],
      where: [
        "recordId",
        "==",
        recordId,
        "roundId",
        "==",
        roundId,
        if (players != null) ...[
          "id",
          "in",
          players.where((id) => id != myId).toList()
        ] else ...[
          "id",
          "!=",
          myId,
        ],
      ],
      order: ["time"],
      start: time == null ? null : [time, true]);
}

String getId(List<String> path) {
  return fm.getId(path);
}

Future<PrivateKey?> getPrivateKey() async {
  return fm.getValue((map) => PrivateKey.fromMap(map), ["admin", "keys"]);
}

void updateUserToken(String userId, List<String> tokens) async {
  final value = {"tokens": tokens, "time_modified": timeNow};
  await fm.updateValue(["users", myId], value: value);
  saveUserProperty(userId, value);
}

void updateToken(String token) async {
  if (!kIsWeb && Platform.isWindows) return;
  if (myId.isEmpty) return;
  final prevToken = sharedPref.getString("token");
  if (token == prevToken) return;
  final myUser = await getUser(myId);

  final tokens = myUser?.tokens ?? [];

  if (prevToken != null && tokens.contains(prevToken)) {
    tokens.remove(prevToken);
  }
  tokens.add(token);
  final value = {"tokens": tokens, "time_modified": timeNow};

  await fm.setValue(["users", myId], value: value, merge: true);
  sharedPref.setString("token", token);
  saveUserProperty(myId, value);
}

Future<String?> getToken(String userId) async {
  return fm.getValue((map) => map["token"], ["users", userId]);
}

Future sendNotification(String userId) async {
  final token = await getToken(userId);
  if (token == null) return;
}

void updatePresence() {
  FirebaseMethods fm = FirebaseMethods();
  final connref = fm.database.ref(".info/connected");
  connref.onValue.listen((event) async {
    final connected = event.snapshot.value as bool? ?? false;
    final user = fm.auth.currentUser;
    if (user != null && user.emailVerified) {
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
