import 'package:gamesarena/shared/utils/utils.dart';

import '../../core/firebase/firestore_methods.dart';
import '../user/models/user_game.dart';

FirestoreMethods fm = FirestoreMethods();

Future updateProfilePhoto(String url) async {
  return fm.updateValue(["users", myId], value: {"profile_photo": url});
}

Future removeProfilePhoto() async {
  return fm.updateValue(["users", myId], value: {"profile_photo": null});
}

Future updateUserGames(List<UserGame> userGames) async {
  return fm.updateValue([
    "users",
    myId
  ], value: {
    "user_games": userGames.map((userGame) => userGame.toMap()).toList()
  });
}

Future updateGroupUserGames(String gameId, List<UserGame> userGames) async {
  return fm.updateValue([
    "games",
    gameId
  ], value: {
    "user_games": userGames.map((userGame) => userGame.toMap()).toList()
  });
}
