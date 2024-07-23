import 'package:gamesarena/core/firebase/firestore_methods.dart';

import '../../../shared/utils/utils.dart';
import '../game/models/game.dart';
import '../game/models/playing.dart';
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

Future<User?> getUser(String userId) async {
  return fm.getValue<User>((map) => User.fromMap(map), ["users", userId]);
}

Future<List<User>> searchUser(String type, String searchString) async {
  return fm.getValues<User>((map) => User.fromMap(map), ["users"],
      where: [type, "==", searchString.toLowerCase().trim()]);
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

Future<List<User>> getPlayersFromGame(String gameId) async {
  final game = await fm.getValue((map) => Game.fromMap(map), ["games", gameId]);
  if (game == null) return [];
  final players = game.players;
  final playerIds = players.split(",");
  return playersToUsers(playerIds);
}
