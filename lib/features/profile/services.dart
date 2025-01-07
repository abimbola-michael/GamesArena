import 'package:gamesarena/shared/utils/utils.dart';

import '../../core/firebase/firestore_methods.dart';
import '../user/models/user_game.dart';
import '../user/services.dart';

FirestoreMethods fm = FirestoreMethods();

Future updateProfilePhoto(String url) async {
  return fm.updateValue(["users", myId], value: {"profile_photo": url});
}

Future removeProfilePhoto() async {
  return fm.updateValue(["users", myId], value: {"profile_photo": null});
}

Future updateGroupProfilePhoto(String gameId, String url) async {
  return fm.updateValue(["games", gameId], value: {"profile_photo": url});
}

Future removeGroupProfilePhoto(String gameId) async {
  return fm.updateValue(["games", gameId], value: {"profile_photo": null});
}

Future updateUserGames(List<String> games) async {
  final value = {"games": games};
  await fm.updateValue(["users", myId], value: value);
  saveUserProperty(myId, value);
}

Future updateGroupGames(String gameId, List<String> games) async {
  return fm.updateValue(["games", gameId], value: {"games": games});
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
