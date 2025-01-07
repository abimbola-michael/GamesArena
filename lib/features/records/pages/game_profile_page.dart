import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/features/game/models/game_list.dart';
import 'package:gamesarena/features/game/services.dart';
import 'package:gamesarena/features/records/views/matches_listview.dart';
import 'package:gamesarena/features/records/views/players_listview.dart';
import 'package:gamesarena/features/records/services.dart';
import 'package:gamesarena/features/records/widgets/game_stat_item.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/views/empty_listview.dart';
import 'package:gamesarena/shared/widgets/app_appbar.dart';
import 'package:hive/hive.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../shared/utils/utils.dart';
import '../../../shared/views/loading_view.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_popup_menu_button.dart';
import '../../../theme/colors.dart';
import '../../game/models/game.dart';
import '../../game/models/player.dart';
import '../../game/utils.dart';
import '../../game/widgets/players_profile_photo.dart';
import '../../game/widgets/profile_photo.dart';
import '../../players/pages/players_selection_page.dart';
import '../../profile/pages/profile_page.dart';
import '../models/game_stat.dart';
import '../utils/utils.dart';

class GameProfilePage extends StatefulWidget {
  final GameList? gameList;
  const GameProfilePage({super.key, required this.gameList});

  @override
  State<GameProfilePage> createState() => _GameProfilePageState();
}

class _GameProfilePageState extends State<GameProfilePage>
    with SingleTickerProviderStateMixin {
  GameStat? gameStat;
  late TabController tabController;
  List<String> tabs = ["Players", "Plays", "Wins", "Draws", "Losses"];
  Player? myPlayer;
  String myRole = "";
  bool loading = false;
  Game? game;
  String gameId = "";
  List<Player> players = [];
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabs.length, vsync: this);
    game = widget.gameList?.game;
    gameId = widget.gameList?.game_id ?? "";
    gameStat = game?.gameStat;

    getDetails();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void getDetails() async {
    loading = true;
    setState(() {});

    final game = this.game;
    if (game == null) return;
    try {
      gameStat = await getGameStats(gameId, game.players?.length);
      if (widget.gameList?.game != null) {
        widget.gameList!.game!.gameStat = gameStat;
        final gameListBox = Hive.box<String>("gamelists");
        gameListBox.put(gameId, widget.gameList!.toJson());
      }
    } catch (e) {
      gameStat = widget.gameList?.game?.gameStat;
    }

    if (game.creatorId != null && game.creatorId != myId) {
      final creatorPlayer = await getPlayer(game.game_id, game.creatorId!);

      if (creatorPlayer != null) {
        creatorPlayer.user ??= await getUser(creatorPlayer.id);
        players.add(creatorPlayer);
      }
    }
    final myPlayer = await getPlayer(game.game_id, myId);
    if (myPlayer != null) {
      myPlayer.user ??= await getUser(myPlayer.id);
      players.add(myPlayer);
      myRole = myPlayer.role ?? "";
    }
    loading = false;
    setState(() {});
  }

  void gotoAddPlayers() async {
    if (game?.game_id == null) return;

    final result = await context.pushTo(PlayersSelectionPage(
      type: "group",
      gameId: game?.game_id,
      groupName: game?.groupName,
    ));

    if (result != null) {
      final playerIds = result as List<String>;
      if (playerIds.isEmpty) return;
      final players = await addPlayersToGameGroup(game!.game_id, playerIds);
      gameStat?.players += players.length;
      players.addAll(players);
      setState(() {});
    }
  }

  void gotoEditGroupProfile(bool canEditGroup) {
    context.pushTo(ProfilePage(
      id: gameId,
      name: game?.groupName,
      profilePhoto: game?.profilePhoto,
      isGroup: game?.groupName != null,
      canEditGroup: canEditGroup,
      games: game?.games,
    ));
  }

  void deleteGroup() async {
    await deleteGameGroup(gameId);
    if (!mounted) return;
    context.pop();
  }

  void exitGroup() async {
    await exitGameGroup(gameId);
    if (!mounted) return;
    context.pop();
  }

  void executeGroupOptions(String option) {
    switch (option) {
      case "Leave Group":
        exitGroup();
        break;
      case "Edit Group":
      case "View Group":
        gotoEditGroupProfile(option == "Edit Group");
        break;
      case "Add Players":
        gotoAddPlayers();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> options = [];
    if (myRole != "participant") {
      options.addAll(["Edit Group", "Add Players"]);
    } else {
      options.addAll(["View Group"]);
    }
    options.add("Leave Group");
    return Scaffold(
      appBar: AppAppBar(
        title: "Game Profile",
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (game?.groupName != null)
              AppPopupMenuButton(
                  options: options, onSelected: executeGroupOptions)
            // PopupMenuButton<String>(
            //   itemBuilder: (context) {

            //     return List.generate(options.length, (index) {
            //       final option = options[index];
            //       return PopupMenuItem<String>(
            //           value: option,
            //           child: Text(
            //             option,
            //             style: context.bodyMedium,
            //           ));
            //     });
            //   },
            //   onSelected: executeGroupOptions,
            //   child: const Icon(EvaIcons.more_vertical),
            // )
          ],
        ),
      ),
      body: loading
          ? const LoadingView()
          : Column(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (game?.users != null)
                      PlayersProfilePhoto(
                        users: game!.users!,
                        withoutMyId: true,
                        size: 100,
                      )
                    else if ((game?.groupName ?? "").isNotEmpty)
                      ProfilePhoto(
                        profilePhoto: game!.profilePhoto ?? "",
                        name: game!.groupName!,
                        size: 100,
                      ),
                    const SizedBox(height: 10),
                    Text(
                      game?.users != null
                          ? getOtherPlayersUsernames(game!.users!)
                          : game?.groupName != null
                              ? game!.groupName!
                              : "",
                      style: TextStyle(
                        fontSize: 20,
                        color: tint,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (game?.games != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        getGamesString(game!.games),
                        style: context.bodySmall?.copyWith(color: lighterTint),
                      ),
                    ],
                    const SizedBox(height: 5),
                    if (gameStat != null)
                      Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            //crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              GameStatItem(
                                title: "Players",
                                count: gameStat!.players,
                                onPressed: () {
                                  tabController.animateTo(0);
                                },
                              ),
                              GameStatItem(
                                title: "Matches",
                                count: gameStat!.allMatches,
                                onPressed: () {
                                  context.pop();
                                },
                              ),
                              GameStatItem(
                                title: "Plays",
                                count: gameStat!.playedMatches,
                                onPressed: () {
                                  tabController.animateTo(1);
                                },
                              ),
                              GameStatItem(
                                title: "Wins",
                                count: gameStat!.wins,
                                onPressed: () {
                                  tabController.animateTo(2);
                                },
                              ),
                              GameStatItem(
                                title: "Draws",
                                count: gameStat!.draws,
                                onPressed: () {
                                  tabController.animateTo(3);
                                },
                              ),
                              GameStatItem(
                                title: "Losses",
                                count: gameStat!.losses,
                                onPressed: () {
                                  tabController.animateTo(4);
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
                TabBar(
                  controller: tabController,
                  padding: EdgeInsets.zero,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  dividerColor: transparent,
                  tabs: List.generate(tabs.length, (index) {
                    final tab = tabs[index];
                    return Tab(text: tab);
                  }),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      if (game != null && players.isNotEmpty)
                        PlayersListView(game: game!, players: players)
                      else
                        Container(),
                      // const EmptyListView(message: "No player"),
                      MatchesListView(gameId: gameId),
                      MatchesListView(gameId: gameId, type: "win"),
                      MatchesListView(gameId: gameId, type: "draw"),
                      MatchesListView(gameId: gameId, type: "loss"),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
