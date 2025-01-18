import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/game/models/game_list.dart';
import 'package:gamesarena/features/game/services.dart';
import 'package:gamesarena/features/players/views/players_listview.dart';
import 'package:gamesarena/features/records/services.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/widgets/app_appbar.dart';
import 'package:hive/hive.dart';

import '../../../main.dart';
import '../../../shared/constants.dart';
import '../../../shared/extensions/special_context_extensions.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/views/loading_view.dart';
import '../../../shared/widgets/app_popup_menu_button.dart';
import '../../../shared/widgets/hinting_widget.dart';
import '../../../theme/colors.dart';
import '../../game/models/game.dart';
import '../../game/models/player.dart';
import '../../game/utils.dart';
import '../../game/widgets/players_profile_photo.dart';
import '../../game/widgets/profile_photo.dart';
import '../../match/pages/game_matches_page.dart';
import '../../match/providers/gamelist_provider.dart';
import '../../players/pages/players_selection_page.dart';
import 'profile_page.dart';
import '../../records/models/game_stat.dart';
import '../../records/utils/utils.dart';

class GameProfilePage extends ConsumerStatefulWidget {
  final GameList? gameList;
  const GameProfilePage({super.key, required this.gameList});

  @override
  ConsumerState<GameProfilePage> createState() => _GameProfilePageState();
}

class _GameProfilePageState extends ConsumerState<GameProfilePage>
    with SingleTickerProviderStateMixin {
  GameStat? gameStat;
  late TabController tabController;
  List<String> tabs = [
    "Players",
    "Matches",
    "Plays",
    "Wins",
    "Draws",
    "Losses",
    "Incompletes",
    "Misseds"
  ];
  Player? myPlayer;
  String myRole = "";
  bool loading = false, loadingStat = false;
  Game? game;
  String gameId = "";
  List<Player> players = [];
  //int matchesCount = 0;
  List<int> visitedTabs = [];
  Map<int, int> tabCounts = {};

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabs.length, vsync: this);
    game = widget.gameList?.game;
    gameId = widget.gameList?.game_id ?? "";
    gameStat = game?.gameStat;

    addTabListener();
    getDetails();

    //getProfileGameStats();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  String getTabMatchType(String tab) {
    if (tab.contains(" ")) {
      tab = tab.split(" ").last;
    }
    switch (tab) {
      case "Matches":
        return "";
      case "Plays":
        return "play";
      case "Wins":
        return "win";
      case "Draws":
        return "draw";
      case "Losses":
        return "loss";
      case "Incompletes":
        return "incomplete";
      case "Misseds":
        return "missed";
    }
    return "";
  }

  void addTabListener() {
    tabController.addListener(() {
      final changing = tabController.indexIsChanging;
      if (!changing) {
        final index = tabController.index;
        updateTabCount(index);
      }
    });
  }

  void updateTabCount(int index) {
    final tab = tabs[index];
    if (visitedTabs.contains(index)) {
      return;
    }

    if (index == 0) {
      if (game?.players != null && game!.players!.isNotEmpty) {
        final value = game!.players!.length;
        tabs[index] = "$value ${tabs[index]}";
      } else {
        getPlayersCount(gameId).then((value) {
          tabCounts[index] = value;

          if (value != -1) {
            tabs[index] = "$value ${tabs[index]}";
          }
          if (!mounted) return;
          setState(() {});
        });
      }
    } else {
      getPlayedMatchesCount(gameId, getTabMatchType(tab)).then((value) {
        tabCounts[index] = value;

        if (value != -1) {
          tabs[index] = "$value ${tabs[index]}";
        }
        if (!mounted) return;

        setState(() {});
      });
    }

    visitedTabs.add(index);
  }

  void getProfileGameStats() async {
    if (game == null) return;
    loadingStat = true;
    setState(() {});
    try {
      gameStat = await getGameStats(gameId, game!.players?.length);
      if (widget.gameList?.game != null) {
        widget.gameList!.game!.gameStat = gameStat;
        final gameListBox = Hive.box<String>("gamelists");
        gameListBox.put(gameId, widget.gameList!.toJson());
      }
    } catch (e) {
      gameStat = widget.gameList?.game?.gameStat;
    }
    loadingStat = false;
    setState(() {});
  }

  void getDetails() async {
    updateTabCount(0);

    loading = true;
    setState(() {});

    final game = this.game;
    if (game == null) return;

    // matchesCount = await getPlayedMatchesCount(gameId, "");
    // tabCounts[0] = matchesCount;

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

  Future addUsersToPlayers(List<Player> players) async {
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      player.user ??= await getUser(player.id);
    }
  }

  void gotoAddPlayers() async {
    if (game?.game_id == null) return;

    final result = await context.pushTo(PlayersSelectionPage(
      type: "group",
      gameId: game?.game_id,
      groupName: game?.groupName,
      isAddPlayers: true,
    ));

    if (result != null) {
      final playerIds = result as List<String>;
      if (playerIds.isEmpty) return;

      showLoading(message: "Adding Players");

      final newPlayers = await addPlayersToGameGroup(game!.game_id, playerIds);
      final insertIndex = players.indexWhere((player) =>
          player.id != game?.creatorId &&
          player.id != myId &&
          player.role == "participant");

      await addUsersToPlayers(newPlayers);

      if (insertIndex != -1) {
        players.insertAll(insertIndex, newPlayers);
      } else {
        players.addAll(newPlayers);
      }
      hideDialog();

      setState(() {});
    }
  }

  void executeProfileChanges(Map<String, dynamic> map) {
    if (map["name"] != null) {
      game?.groupName = map["name"];
    }
    if (map["profilePhoto"] != null) {
      game?.profilePhoto = map["profilePhoto"];
    }
    if (map["games"] != null) {
      game?.games = map["games"];
    }

    if (map["time"] != null) {
      game?.time_modified = map["time"];
    }
    widget.gameList?.game = game;
    ref.read(gamelistProvider.notifier).updateGameList(widget.gameList);

    setState(() {});
  }

  void gotoEditGroupProfile(bool canEditGroup) {
    context.pushTo(ProfilePage(
      id: gameId,
      name: game?.groupName,
      profilePhoto: game?.profilePhoto,
      isGroup: game?.groupName != null,
      canEditGroup: canEditGroup,
      games: game?.games,
      onChanged: executeProfileChanges,
    ));
  }

  void deleteGroup() async {
    await deleteGameGroup(gameId);
    if (!mounted) return;
    context.pop();
  }

  void exitGroup() async {
    final comfirm = await context.showComfirmationDialog(
        title: "Leave Group", message: "Are you sure you want to leave group");
    if (comfirm != true) return;

    final time = timeNow;
    //await exitGameGroup(gameId);
    await removePlayerFromGameGroup(gameId, myId, time);

    final gameListBox = Hive.box<String>("gamelists");
    final prevGameListJson = gameListBox.get(gameId);
    if (prevGameListJson != null) {
      final prevGameList = GameList.fromJson(prevGameListJson);
      prevGameList.time_end = time;
      prevGameList.time_modified = time;
      prevGameList.user_id = myId;
      gameListBox.put(gameId, prevGameList.toJson());
      ref.read(gamelistProvider.notifier).updateGameList(prevGameList);
    }

    // updateGameListTime(gameId, timeEnd: timeNow);
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
              HintingWidget(
                showHint: sharedPref.getBool(TAPPED_GAME_PROFILE_MORE) == null,
                hintText: "Tap for more",
                bottom: 0,
                right: 0,
                child: AppPopupMenuButton(
                  options: options,
                  onSelected: executeGroupOptions,
                  onOpened: () {
                    if (sharedPref.getBool(TAPPED_GAME_PROFILE_MORE) != true) {
                      sharedPref
                          .setBool(TAPPED_GAME_PROFILE_MORE, true)
                          .then((value) {
                        setState(() {});
                      });
                    }
                  },
                ),
              )
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
                    const SizedBox(height: 4),
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
                    // const SizedBox(height: 5),
                    // if (matchesCount > 0)
                    //   InkWell(
                    //     onTap: () => context.pop(),
                    //     child: Row(
                    //       mainAxisSize: MainAxisSize.min,
                    //       children: [
                    //         Text(
                    //           "$matchesCount",
                    //           style: context.bodyLarge?.copyWith(
                    //               color: primaryColor,
                    //               fontWeight: FontWeight.bold),
                    //         ),
                    //         const SizedBox(width: 4),
                    //         Text(
                    //           "Matches",
                    //           style: context.bodyLarge?.copyWith(),
                    //         ),
                    //       ],
                    //     ),
                    //   )
                    // if (loadingStat)
                    //   const SizedBox(
                    //     height: 60,
                    //     child: Center(
                    //       child: CircularProgressIndicator(),
                    //     ),
                    //   ),
                    // if (gameStat != null)
                    //   Center(
                    //     child: SingleChildScrollView(
                    //       scrollDirection: Axis.horizontal,
                    //       child: Row(
                    //         mainAxisSize: MainAxisSize.min,
                    //         //crossAxisAlignment: WrapCrossAlignment.center,
                    //         children: [
                    //           GameStatItem(
                    //             title: "Players",
                    //             count: gameStat!.players,
                    //             onPressed: () {
                    //               tabController.animateTo(0);
                    //             },
                    //           ),
                    //           GameStatItem(
                    //             title: "Matches",
                    //             count: gameStat!.allMatches,
                    //             onPressed: () {
                    //               context.pop();
                    //             },
                    //           ),
                    //           GameStatItem(
                    //             title: "Plays",
                    //             count: gameStat!.playedMatches,
                    //             onPressed: () {
                    //               tabController.animateTo(1);
                    //             },
                    //           ),
                    //           GameStatItem(
                    //             title: "Wins",
                    //             count: gameStat!.wins,
                    //             onPressed: () {
                    //               tabController.animateTo(2);
                    //             },
                    //           ),
                    //           GameStatItem(
                    //             title: "Draws",
                    //             count: gameStat!.draws,
                    //             onPressed: () {
                    //               tabController.animateTo(3);
                    //             },
                    //           ),
                    //           GameStatItem(
                    //             title: "Losses",
                    //             count: gameStat!.losses,
                    //             onPressed: () {
                    //               tabController.animateTo(4);
                    //             },
                    //           ),
                    //           GameStatItem(
                    //             title: "Incompletes",
                    //             count: gameStat!.incompletes,
                    //             onPressed: () {
                    //               tabController.animateTo(5);
                    //             },
                    //           ),
                    //           GameStatItem(
                    //             title: "Misseds",
                    //             count: gameStat!.misseds,
                    //             onPressed: () {
                    //               tabController.animateTo(6);
                    //             },
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   )
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
                    children: List.generate(tabs.length, (index) {
                      final tab = tabs[index];
                      final count = tabCounts[index];
                      if (index == 0) {
                        if (game != null && players.isNotEmpty) {
                          return PlayersListView(game: game!, players: players);
                        } else {
                          return Container();
                        }
                      } else {
                        if (count == null) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return GameMatchesPage(
                            game_id: gameId,
                            type: getTabMatchType(tab),
                            totalSize: count == -1 ? null : count);
                      }
                    }),
                  ),
                )
              ],
            ),
    );
  }
}
