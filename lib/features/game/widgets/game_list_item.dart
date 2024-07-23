import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/models.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/utils.dart';
import '../../records/services.dart';
import '../../user/services.dart';
import '../services.dart';

class GameListItem extends StatefulWidget {
  final GameList gameList;
  final VoidCallback onPressed;

  const GameListItem(
      {super.key, required this.gameList, required this.onPressed});

  @override
  State<GameListItem> createState() => _GameListItemState();
}

class _GameListItemState extends State<GameListItem> {
  late GameList gameList;
  User? user;
  List<User> users = [];
  Group? group;
  Match? match;
  Game? game;
  String game_id = "", type = "";
  String name = "";
  String lastSeen = "";
  String matchMessage = "";
  List<String> players = [];
  List<MatchRecord> matchRecords = [];
  int missedMatchesCount = 0;
  @override
  void initState() {
    super.initState();
    //myId = myId;
    gameList = widget.gameList;
    game_id = gameList.game_id;
    getGameDetails();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(8),
      onTap: widget.onPressed,
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: darkMode ? lightestWhite : lightestBlack,
            radius: 30,
            child: Text(
              name.firstChar ?? "",
              style: const TextStyle(fontSize: 30, color: Colors.blue),
            ),
          ),
          // if (lastSeen == "") ...[
          //   const Positioned(
          //     bottom: 4,
          //     right: 4,
          //     child: CircleAvatar(
          //       radius: 4,
          //       backgroundColor: Colors.green,
          //     ),
          //   )
          // ],
        ],
      ),
      trailing: match == null
          ? null
          : Text(
              match!.time_created?.datetime.timeRange() ?? "",
              style: TextStyle(
                  fontSize: 14,
                  color: darkMode
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.7)),
            ),
      title: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 16,
            color: darkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      subtitle: match == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  match!.creator_id == myId
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: match!.creator_id != myId &&
                          (match!.time_start == "" || match!.time_start == null)
                      ? Colors.red
                      : Colors.blue,
                  size: 15,
                ),
                const SizedBox(
                  width: 4,
                ),
                Text(
                  matchMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: match!.creator_id != myId &&
                            (match!.time_start == "" ||
                                match!.time_start == null)
                        ? Colors.red
                        : darkMode
                            ? Colors.white
                            : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
    );
  }

  void getGameDetails() async {
    final game = await getGame(game_id);
    this.game = game;
    if (game != null) {
      List<String> ids = game.players.split(",");
      users = await playersToUsers(ids);
      final opponentUsers =
          users.where((element) => element.user_id != myId).toList();
      name = opponentUsers.toStringWithCommaandAnd((user) => user.username);
      setState(() {});
    }
    final matches = await getMatches(game_id);
    final match = matches.isNotEmpty ? matches.last : null;
    this.match = match;
    if (match != null) {
      if (match.time_start != null && match.time_start != "") {
        matchRecords = await getMatchRecords(game_id, match.match_id!);
        matchMessage = matchRecords.isEmpty
            ? "0 games"
            : "${matchRecords.last.game} - ${matchRecords.length} game${matchRecords.length == 1 ? "" : "s"}";
      } else {
        getMissedMatchCount(matches);
        matchMessage =
            "$missedMatchesCount Missed match${missedMatchesCount == 1 ? "" : "es"}";
      }
    }
    setState(() {});
  }

  void getMissedMatchCount(List<Match> matches) {
    for (int i = matches.length - 1; i >= 0; i--) {
      final match = matches[i];
      if (match.time_start == "" || match.time_start == null) {
        missedMatchesCount++;
      } else {
        return;
      }
    }
  }
}
