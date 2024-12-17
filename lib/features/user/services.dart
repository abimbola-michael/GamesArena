import 'package:gamesarena/core/firebase/firestore_methods.dart';
import 'package:hive/hive.dart';

import '../../../shared/utils/utils.dart';
import '../../main.dart';
import '../game/models/game.dart';
import '../game/models/player.dart';
import 'models/user.dart';

FirestoreMethods fm = FirestoreMethods();

Future updateUserDetails(String type, String value) async {
  return fm.updateValue(["users", myId], value: {type: value});
}

// Future createUser(User user) async {
//   await fm.setValue(["users", user.user_id], value: user.toMap());
// }

Stream<User?> getStreamUser(String userId) async* {
  yield* fm.getValueStream<User>((map) => User.fromMap(map), ["users", userId]);
}

// Future<User?> getUser(String userId) async {
//   return fm.getValue<User>((map) => User.fromMap(map), ["users", userId]);
// }

Future deleteUser() async {
  return fm.updateValue(["users", myId], value: {"deleted_at": timeNow});

  // return fm.removeValue(["users", userId]);
}

Future<List<User>> searchUser(String type, String searchString) async {
  return fm.getValues<User>((map) => User.fromMap(map), ["users"],
      where: [type, "==", searchString.toLowerCase().trim()]);
}

Future<List<User>> playersToUsers(List<String> players,
    {bool useCache = true}) async {
  List<User> users = [];
  for (int i = 0; i < players.length; i++) {
    final player = players[i];
    final user = await getUser(player, useCache: useCache);
    if (user != null) {
      users.add(user);
    }
  }

  return users;
}

Future<List<User?>> playingToUsers(List<Player> players) async {
  List<User?> users = [];
  for (int i = 0; i < players.length; i++) {
    final player = players[i];
    final user = await getUser(player.id);
    users.add(user);
  }

  return users;
}

Future<List<User>> getPlayersFromGame(String gameId) async {
  final game = await fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
  if (game == null) return [];
  final players = game.players;
  final playerIds = players ?? [];
  return playersToUsers(playerIds);
}

Future<User?> getUser(String userId, {bool useCache = true}) async {
  if (useCache) {
    if (usersMap.containsKey(userId)) {
      final mapValue = usersMap[userId];
      return mapValue;
    }
  }
  final usersBox = Hive.box<String>("users");

  try {
    final user =
        await fm.getValue((map) => User.fromMap(map), ["users", userId]);
    usersBox.put(userId, user?.toJson() ?? "");
    usersMap[userId] = user;
    return user;
  } catch (e) {
    String? userJson = usersBox.get(userId);
    return (userJson ?? "").isEmpty ? null : User.fromJson(userJson!);
  }
}
