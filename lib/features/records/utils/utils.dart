import '../../user/models/user.dart';
import '../../user/models/user_game.dart';

String getUserGamesString(List<UserGame>? userGames) {
  return userGames
          ?.map((userGame) => "${userGame.name}(${userGame.ability})")
          .join(", ") ??
      "";
}
