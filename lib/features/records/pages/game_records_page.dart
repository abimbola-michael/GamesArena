import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/game/models/game_list.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/home/tabs/games_page.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/utils/utils.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../shared/services.dart';
import 'package:gamesarena/features/game/models/match.dart';

import '../../../shared/views/empty_listview.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_popup_menu_button.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../theme/colors.dart';
import '../../game/services.dart';
import '../../game/utils.dart';
import '../../game/widgets/match_list_item.dart';
import '../../game/models/game.dart';
import '../../game/widgets/players_profile_photo.dart';
import '../../game/widgets/profile_photo.dart';
import '../../home/providers/search_matches_provider.dart';
import '../../players/pages/players_selection_page.dart';
import '../../user/models/user.dart';
import '../../user/services.dart';
import 'game_profile_page.dart';

class GameRecordsPage extends ConsumerStatefulWidget {
  final GameList? gameList;
  final String game_id;
  final String id;
  final String type;
  const GameRecordsPage(
      {super.key,
      required this.game_id,
      required this.id,
      required this.type,
      this.gameList});

  @override
  ConsumerState<GameRecordsPage> createState() => _GameRecordsPageState();
}

class _GameRecordsPageState extends ConsumerState<GameRecordsPage> {
  String name = "";
  String type = "", id = "", game_id = "";
  Game? game;
  List<Match> matches = [];
  List<User> users = [];
  List<String> players = [];
  GameList? gameList;
  Box<String>? gameListsBox;
  bool loading = false;
  bool isSearch = false;
  final searchController = TextEditingController();

  List<String> menuOptions = ["View Profile", "Clear Matches"];

  @override
  void initState() {
    super.initState();
    type = widget.type;
    id = widget.id;
    game_id = widget.game_id;
    getDetails();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> getDetails() async {
    //final matchesBox = Hive.box<String>("matches");
    gameListsBox = Hive.box<String>("gamelists");
    final gameListValue = gameListsBox!.get(game_id);
    gameList ??=
        gameListValue == null ? null : GameList.fromJson(gameListValue);
    if (gameList == null) return;
    if (gameList!.game != null &&
        gameList!.game!.groupName == null &&
        gameList!.game!.players != null &&
        gameList!.game!.users == null) {
      players = gameList!.game!.players!;

      List<User> users = await playersToUsers(players);

      gameList!.game!.users = users;
    }
    if (!mounted) return;
    setState(() {});
  }

  void loadPreviousMatches(String lastTime) async {
    //setState(() {
    loading = true;
    //});
    //lastTime,
    final matches =
        await getPreviousMatches(game_id, time: lastTime, limit: 10);
    final matchesBox = Hive.box<String>("matches");

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      matchesBox.put(match.match_id, match.toJson());
    }
    //setState(() {
    loading = false;
    //});
  }

  void gotoGameProfile() {
    if (gameList == null) return;
    context.pushTo(GameProfilePage(gameList: gameList));
  }

  void startSearch() {
    isSearch = true;
    setState(() {});
  }

  void updateSearch(String value) {
    ref
        .read(searchMatchesProvider.notifier)
        .updateSearch(value.trim().toLowerCase());
  }

  void stopSearch() {
    ref.read(searchMatchesProvider.notifier).updateSearch("");

    searchController.clear();
    isSearch = false;
    setState(() {});
  }

  void clearMatches() {
    final gameListsBox = Hive.box<String>("gamelists");

    final matchesBox = Hive.box<String>("matches");
    final matches = matchesBox.values
        .map((map) => Match.fromJson(map))
        .where((match) => match.game_id == game_id)
        .toList();
    matches.sortList((match) => match.time_modified, true);

    matchesBox.deleteAll(matches.map((match) => match.match_id));
    final gameListJson = gameListsBox.get(game_id);
    if (gameListJson != null) {
      final gameList = GameList.fromJson(gameListJson);
      gameList.match = null;
      gameList.time_seen = null;
      gameList.time_start = matches.firstOrNull?.time_modified;
      gameList.unseen = 0;
      gameListsBox.put(game_id, gameList.toJson());
    }
  }

  void executeMenuOptions(String option) {
    final index = menuOptions.indexOf(option);
    switch (index) {
      case 0:
        gotoGameProfile();
        break;
      case 1:
        clearMatches();
        break;
    }
  }

  void playMatch() {
    context.pushTo(
      GamesPage(
          gameId: gameList?.game_id,
          players: gameList?.game?.players,
          groupName: gameList?.game?.groupName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchString = ref.watch(searchMatchesProvider);

    return Scaffold(
      appBar: (isSearch
          ? AppSearchBar(
              hint: "Search Matches",
              controller: searchController,
              onChanged: updateSearch,
              onCloseSearch: stopSearch,
            )
          : AppAppBar(
              middle: GestureDetector(
                onTap: gotoGameProfile,
                child: Row(
                  children: [
                    if (gameList?.game?.users != null)
                      PlayersProfilePhoto(
                        users: gameList!.game!.users!,
                        withoutMyId: true,
                      )
                    else if ((gameList?.game?.groupName ?? "").isNotEmpty)
                      ProfilePhoto(
                        profilePhoto: gameList!.game!.profilePhoto ?? "",
                        name: gameList!.game!.groupName!,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            gameList?.game?.users != null
                                ? getOtherPlayersUsernames(
                                    gameList!.game!.users!)
                                : gameList!.game?.groupName != null
                                    ? gameList!.game!.groupName!
                                    : "",
                            style: TextStyle(
                              fontSize: 18,
                              color: tint,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: startSearch,
                    icon: const Icon(EvaIcons.search),
                    color: tint,
                  ),
                  AppPopupMenuButton(
                      options: menuOptions, onSelected: executeMenuOptions)
                ],
              ),
            )) as PreferredSizeWidget?,

      // body: matchesStream == null
      //     ? const Center(
      //         child: Text("Something went wrong"),
      //       )
      //     : StreamBuilder<List<Match>>(
      //         stream: matchesStream,
      //         builder: (context, snapshot) {
      //           if (snapshot.connectionState == ConnectionState.waiting) {
      //             return const Center(
      //               child: CircularProgressIndicator(),
      //             );
      //           }
      //           if (snapshot.hasError) {
      //             return const Center(
      //               child: Text("Something went wrong"),
      //             );
      //           } else if (snapshot.hasData) {
      //             matches = snapshot.data!;
      //             if (matches.isEmpty) {
      //               return const Center(
      //                 child: Text("No Match"),
      //               );
      //             } else {
      //               matches.sortList((match) => match.time_created, true);
      //             }
      //             return ListView.builder(
      //                 itemCount: matches.length,
      //                 itemBuilder: (context, index) {
      //                   return MatchListItem(
      //                     gameId: game_id,
      //                     position: index,
      //                     matches: matches,
      //                     users: users,
      //                   );
      //                 });
      //           } else {
      //             return Container();
      //           }
      //         },
      //       ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<String>("matches").listenable(),
        builder: (context, value, child) {
          final matches = value.values
              .map((map) => Match.fromJson(map))
              .where((match) =>
                  match.game_id == game_id &&
                  (match.players != null
                          ? getAllPlayersUsernames(
                                  playersToUsersLocal(match.players!))
                              .toLowerCase()
                          : "")
                      .contains(searchString.toLowerCase()))
              .toList();
          if (matches.isEmpty) {
            return const EmptyListView(message: "No match");
          }

          matches.sortList((match) => match.time_created, true);
          if (gameList != null && (gameList?.unseen ?? 0) > 0) {
            gameList!.unseen = 0;
            gameListsBox!.put(game_id, gameList!.toJson());
          }
          if (matches.isNotEmpty) {
            final firstMatch = matches.first;
            if (gameList != null &&
                firstMatch.time_created != null &&
                gameList!.time_seen != firstMatch.time_created!) {
              gameList!.time_seen = firstMatch.time_created!;
              gameListsBox!.put(game_id, gameList!.toJson());
              updateInfosSeen(game_id, firstMatch.time_created!);
            }
          }

          return ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                if (index == matches.length - 1 && !loading) {
                  final time = gameList?.time_start ?? gameList?.time_created;
                  if (time != null &&
                      matches.last.time_created!.toInt < time.toInt) {
                    loadPreviousMatches(matches.last.time_created!);
                  }
                }
                return MatchListItem(
                  key: Key(match.match_id ?? "$index"),
                  position: index,
                  matches: matches,
                );
              });
        },
      ),

      bottomNavigationBar: AppButton(
        title: "Play",
        onPressed: playMatch,
      ),
    );
  }
}
