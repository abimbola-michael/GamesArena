import 'package:gamesarena/shared/utils/utils.dart';

import '../../core/firebase/firestore_methods.dart';
import '../user/models/user_game.dart';
import '../user/services.dart';

FirestoreMethods fm = FirestoreMethods();

Future updateProfilePhoto(String url, [String? time]) async {
  time ??= timeNow;

  return fm.updateValue(["users", myId], value: {"profile_photo": url});
}

Future removeProfilePhoto([String? time]) async {
  time ??= timeNow;

  return fm.updateValue(["users", myId],
      value: {"profile_photo": null, "time_modified": time});
}

Future updateGroupProfilePhoto(String gameId, String url,
    [String? time]) async {
  time ??= timeNow;

  return fm.updateValue(["games", gameId],
      value: {"profile_photo": url, "time_modified": time});
}

Future removeGroupProfilePhoto(String gameId, [String? time]) async {
  time ??= timeNow;

  return fm.updateValue(["games", gameId],
      value: {"profile_photo": null, "time_modified": time});
}

Future updateUserGames(List<String> games, [String? time]) async {
  time ??= timeNow;
  final value = {"games": games, "time_modified": time};
  await fm.updateValue(["users", myId], value: value);
  saveUserProperty(myId, value);
}

Future updateGroupGames(String gameId, List<String> games,
    [String? time]) async {
  time ??= timeNow;

  return fm.updateValue(["games", gameId],
      value: {"games": games, "time_modified": time});
}
// Future updateUserGames(List<UserGame> userGames) async {
//   final value = {
//     "user_games": userGames.map((userGame) => userGame.toMap()).toList()
//   };
//   await fm.updateValue(["users", myId], value: value);
//   saveUserProperty(myId, value);
// }

// Future updateGroupGames(String gameId, List<UserGame> userGames) async {
//   return fm.updateValue([
//     "games",
//     gameId
//   ], value: {
//     "user_games": userGames.map((userGame) => userGame.toMap()).toList()
//   });
// }
