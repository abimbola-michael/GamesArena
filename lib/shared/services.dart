import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gamesarena/core/firebase/firebase_notification.dart';
import 'package:gamesarena/core/firebase/firebase_methods.dart';
import 'package:gamesarena/core/firebase/firestore_methods.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import '../features/user/services.dart';
import 'models/private_key.dart';

import 'models/models.dart';
import 'utils/utils.dart';

FirestoreMethods fm = FirestoreMethods();

// Stream<Map<String, dynamic>?> getGameDetails(String gameId) async* {
//   yield* fm.getValueStream((map) => map, ["games", gameId, "details"]);
// }
Future setGameDetails(String gameId, Map<String, dynamic> map) async {
  return fm.setValue(["games", gameId, "details"], value: map);
}

Stream<List<ValueChange<Map<String, dynamic>>>> getGameDetailsChange(
    String gameId) async* {
  yield* fm.getValuesChangeStream((map) => map, ["games", gameId, "details"]);
}

Future sendPushNotificationToPlayers(String game, List<String> players) async {
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
    // final key = await getPrivateKey();
    // if (key == null) return;
    // String firebaseAuthKey = key.firebaseAuthKey;
    final token = await getToken(player);
    //final phoneToken = await FirebaseMessaging.instance.getToken();
    //phoneToken == token
    if (token == null || token == "") return;
    final body =
        "$creatorName will like to play $game game with ${otherUsernames.toStringWithCommaandAnd((username) => username)}";
    await sendPushNotification(token, creatorName, body);
  }
}

String getId(List<String> path) {
  return fm.getId(path);
}

Future<PrivateKey?> getPrivateKey() async {
  return fm.getValue((map) => PrivateKey.fromMap(map), ["admin", "keys"]);
}

void updateToken(String token) async {
  if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;
  if (myId != "") {
    await fm.updateValue(["users", myId], value: {"token": token});
  }
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
