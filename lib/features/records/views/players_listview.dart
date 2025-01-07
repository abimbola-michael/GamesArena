import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/game/services.dart';
import 'package:gamesarena/features/records/services.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';

import '../../../shared/dialogs/option_selection_dialog.dart';
import '../../../shared/views/empty_listview.dart';
import '../../../shared/views/loading_view.dart';
import '../../game/models/game.dart';
import '../../game/models/player.dart';
import '../../home/tabs/games_page.dart';
import '../../profile/pages/profile_page.dart';
import '../widgets/player_item.dart';

class PlayersListView extends StatefulWidget {
  final Game game;
  final List<Player> players;
  const PlayersListView({super.key, required this.game, required this.players});

  @override
  State<PlayersListView> createState() => _PlayersListViewState();
}

class _PlayersListViewState extends State<PlayersListView>
    with AutomaticKeepAliveClientMixin {
  //List<Player> players = [];
  bool reachedEnd = false, reachedAdminEnd = false;
  bool loading = false;
  int limit = 10;
  String myRole = "";
  int selectedIndex = -1;
  @override
  void initState() {
    super.initState();
    readPlayers();
  }

  void readPlayers([bool isMore = false]) async {
    if (reachedEnd || loading) return;
    setState(() {
      loading = true;
    });

    int playersCount = isMore ? 0 : widget.players.length;

    if (!reachedAdminEnd) {
      final adminPlayers = await getGamePlayers(widget.game,
          lastTime: widget.players.lastOrNull?.time,
          role: "admin",
          limit: limit - playersCount);
      await addUsersToPlayers(adminPlayers);

      widget.players.addAll(adminPlayers);

      if (adminPlayers.length < limit - playersCount) {
        reachedAdminEnd = true;
      }
      playersCount += adminPlayers.length;
    }

    if (playersCount < limit) {
      final participantsPlayers = await getGamePlayers(widget.game,
          lastTime: widget.players.lastOrNull?.time,
          role: "participant",
          limit: limit - playersCount);

      await addUsersToPlayers(participantsPlayers);

      widget.players.addAll(participantsPlayers);

      if (!reachedEnd && participantsPlayers.length < limit - playersCount) {
        reachedEnd = true;
      }
    }

    setState(() {
      loading = false;
    });
  }

  Future addUsersToPlayers(List<Player> players) async {
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      player.user ??= await getUser(player.id);
    }
  }

  void updateRole(Player player, String role) async {
    final String playerId = player.id;
    await updatePlayerRole(widget.game.game_id, playerId, role);
    player.role = role;
    setState(() {});
  }

  void executePlayerOption(Player player, String option) async {
    if (option.startsWith("Play")) {
      bool isPlayInGroup = option.endsWith("group");
      context.pushTo(
        GamesPage(
          gameId: isPlayInGroup ? widget.game.game_id : null,
          players: [myId, player.id],
          groupName: isPlayInGroup ? widget.game.groupName : null,
        ),
      );
    } else if (option.startsWith("View")) {
      context.pushTo(ProfilePage(id: player.id));
    } else if (option.startsWith("Make")) {
      updateRole(player, "admin");
    } else if (option.startsWith("Dismiss")) {
      updateRole(player, "participant");
    } else if (option.startsWith("Remove")) {
      await removePlayerFromGameGroup(widget.game.game_id, player.id);
      widget.players.removeAt(selectedIndex);
      setState(() {});
    }
  }

  void showPlayerOptions(Player player) {
    if (player.id == myId) return;
    final username = player.user?.username ?? "";
    List<String> options = [
      if (widget.game.groupName != null) "Play with $username in group",
      "Play with $username directly",
      "View Profile"
    ];
    if (widget.game.groupName != null) {
      if (myRole == "admin") {
        if (player.role == "participant") {
          options.add("Remove $username");
        }
      } else if (myRole == "creator") {
        if (player.role == "participant") {
          options.add("Make $username an admin");
        } else if (player.role == "admin") {
          options.add("Dismiss as admin");
        }
        options.add("Remove $username");
      }
    }
    showDialog(
        context: context,
        builder: (context) {
          return OptionSelectionDialog(
            options: options,
            onPressed: (index, option) async {
              executePlayerOption(player, option);
              // if (option.startsWith("Play with")) {
              //   final isGroup = option.endsWith("group");
              //   final players = [myId, player.id];
              //   final gameId =
              //       isGroup ? widget.game.game_id : getGameId(players);
              //   context.pushTo(
              //     GamesPage(
              //       gameId: gameId,
              //       players: players,
              //       groupName: isGroup ? widget.game.groupName : null,
              //     ),
              //   );
              // } else if (option.startsWith("View Profile")) {
              //   context.pushTo(ProfilePage(id: player.id));
              // } else if (option.startsWith("Remove")) {
              //   await removePlayerFromGameGroup(widget.game.game_id, player.id);
              //   widget.players.removeAt(index);
              //   setState(() {});
              // } else if (option.startsWith("Make")) {
              // } else if (option.startsWith("Dismiss")) {}
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (loading) {
      return const LoadingView();
    }
    if (widget.players.isEmpty) {
      return const EmptyListView(message: "No player");
    }
    return ListView.builder(
      itemCount: widget.players.length + (loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.players.length - 1 && !reachedEnd && !loading) {
          readPlayers(true);
        }
        if (loading && index == widget.players.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final player = widget.players[index];
        return PlayerItem(
          key: Key(player.id),
          player: player,
          onPressed: () {
            selectedIndex = index;
            showPlayerOptions(player);
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
