import '../../user/models/user.dart';
import '../../user/models/user_game.dart';

String getGamesString(List<String>? games) {
  return games?.join(", ") ?? "";
}
// String getGamesString(List<UserGame>? userGames) {
//   return userGames
//           ?.map((userGame) => "${userGame.name}(${userGame.ability})")
//           .join(", ") ??
//       "";
// }
