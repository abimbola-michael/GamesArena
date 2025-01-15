import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/game/models/game_list.dart';
import 'package:gamesarena/main.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/game/pages/games_page.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/special_context_extensions.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:gamesarena/features/game/models/match.dart';

import '../../../shared/utils/utils.dart';
import '../../../shared/views/empty_listview.dart';
import '../../../shared/views/loading_view.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_popup_menu_button.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../theme/colors.dart';
import '../providers/gamelist_provider.dart';
import '../providers/match_provider.dart';
import '../../game/services.dart';
import '../../game/utils.dart';
import '../widgets/match_list_item.dart';
import '../../game/models/game.dart';
import '../../game/widgets/players_profile_photo.dart';
import '../../game/widgets/profile_photo.dart';
import '../providers/search_matches_provider.dart';
import '../../user/models/user.dart';
import '../../user/services.dart';
import '../../profile/pages/game_profile_page.dart';

class GameMatchesPage extends ConsumerStatefulWidget {
  final GameList? gameList;
  final String game_id;
  final String type;
  const GameMatchesPage(
      {super.key, required this.game_id, this.type = "", this.gameList});

  @override
  ConsumerState<GameMatchesPage> createState() => _GameMatchesPageState();
}

class _GameMatchesPageState extends ConsumerState<GameMatchesPage>
    with AutomaticKeepAliveClientMixin {
  String name = "";
  String type = "", game_id = "";
  Game? game;
  List<Match> matches = [];
  List<User> users = [];
  List<String> players = [];
  GameList? gameList;

  bool loading = false;
  bool isSearch = false;
  bool reachedEnd = false;
  int limit = 10;
  final searchController = TextEditingController();

  List<String> menuOptions = ["View Profile", "Clear Matches"];
  Box<String> matchesBox = Hive.box<String>("matches");
  Box<String> gameListsBox = Hive.box<String>("gamelists");
  @override
  void initState() {
    super.initState();
    type = widget.type;
    game_id = widget.game_id;
    gameList = widget.gameList;

    loadMatches();
    getDetails();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future getDetails() async {
    if (widget.type.isNotEmpty) return;
    final gameListJson = gameListsBox.get(game_id);
    final prevGameList =
        gameListJson == null ? null : GameList.fromJson(gameListJson);

    if (prevGameList == null) return;
    gameList ??= prevGameList;
    if (gameList == null) return;

    if (gameList!.game?.groupName != null) {
      final newGame = await getGame(gameList!.game_id);

      if (gameList!.game?.groupName != newGame?.groupName ||
          gameList!.game?.profilePhoto != newGame?.profilePhoto ||
          gameList!.game?.games != newGame?.games) {
        gameList?.game = newGame;
        gameListsBox.put(game_id, gameList!.toJson());
        ref.read(gamelistProvider.notifier).updateGameList(gameList);
      }
    }

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

  void loadMatches() {
    final allMatches = matchesBox.values.map((map) => Match.fromJson(map));

    switch (widget.type) {
      case "":
        matches =
            allMatches.where((match) => match.game_id == game_id).toList();
        break;
      case "play":
        matches = allMatches
            .where((match) =>
                match.game_id == game_id &&
                match.outcome != "" &&
                match.players!.contains(myId))
            .toList();
        break;
      case "win":
        matches = allMatches
            .where((match) =>
                match.game_id == game_id &&
                match.outcome == "win" &&
                match.winners!.contains(myId))
            .toList();
        break;

      case "draw":
        matches = allMatches
            .where((match) =>
                match.game_id == game_id &&
                match.outcome == "draw" &&
                match.others!.contains(myId))
            .toList();
        break;

      case "loss":
        matches = allMatches
            .where((match) =>
                match.game_id == game_id &&
                match.outcome == "win" &&
                match.others!.contains(myId))
            .toList();
        break;

      case "incomplete":
        matches = allMatches
            .where((match) =>
                match.game_id == game_id &&
                match.outcome != "" &&
                match.time_start != null &&
                match.time_end == null &&
                match.players!.contains(myId))
            .toList();
        break;

      case "missed":
        matches = allMatches
            .where((match) =>
                match.game_id == game_id &&
                match.outcome == "" &&
                match.players!.contains(myId))
            .toList();
        break;
    }

    matches.sortList((match) => match.time_created, true);

    // if (gameList != null && (gameList!.unseen ?? 0) != 0) {
    //   gameList?.unseen = 0;
    //   gameListsBox.put(game_id, gameList!.toJson());
    //   ref.read(gamelistProvider.notifier).updateGameList(gameList);
    // }

    if (widget.type.isEmpty && matches.isNotEmpty) {
      final firstMatch = matches.first;
      if (gameList != null &&
          firstMatch.time_created != null &&
          (gameList!.time_seen == null ||
              gameList!.time_seen!.toInt < firstMatch.time_created!.toInt)) {
        final time = timeNow;

        gameList!.time_seen = firstMatch.time_created!;
        gameList!.unseen = 0;
        gameList!.time_modified = time;
        gameList!.user_id = myId;
        gameListsBox.put(game_id, gameList!.toJson());

        updateGameListTime(game_id,
            timeSeen: firstMatch.time_created!, time: time);
        Future.delayed(const Duration(milliseconds: 300)).then((value) {
          ref.read(gamelistProvider.notifier).updateGameList(gameList);
        });
      }
    }
    setState(() {});
    if (widget.type.isNotEmpty && matches.length < limit) {
      loadPreviousMatches(
          matches.firstOrNull?.time_created ?? gameList?.time_end);
    }
  }

  void loadPreviousMatches([String? lastTime]) async {
    setState(() {
      loading = true;
    });
    final matches = await getPreviousMatches(game_id,
        type: type,
        timeEnd: lastTime,
        timeStart: gameList?.time_start,
        limit: limit);

    if (!reachedEnd && matches.length < limit) {
      reachedEnd = true;
    }

    if (widget.type.isEmpty) {
      Map<String, String> matchesMap = {};
      for (int i = 0; i < matches.length; i++) {
        final match = matches[i];
        matchesMap[match.match_id!] = match.toJson();
      }
      matchesBox.putAll(matchesMap);
    }

    this.matches.addAll(matches);

    setState(() {
      loading = false;
    });
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

  void clearMatches() async {
    final comfirm = await context.showComfirmationDialog(
        title: "Clear Matches",
        message: "Are you sure you want to clear all matches");
    if (comfirm != true) return;

    if (matches.isEmpty) return;

    final time = timeNow;
    final timeStart = matches.firstOrNull?.time_created;

    final gameListJson = gameListsBox.get(game_id);
    if (gameListJson != null) {
      final gameList = GameList.fromJson(gameListJson);

      await updateGameListTime(game_id,
          timeStart: timeStart, timeSeen: null, time: time);

      gameList.match = null;
      gameList.time_seen = null;
      gameList.time_start = timeStart;
      gameList.time_modified = time;
      gameList.unseen = 0;
      gameList.user_id = myId;

      matchesBox.deleteAll(matches.map((match) => match.match_id));

      gameListsBox.put(game_id, gameList.toJson());
      ref.read(gamelistProvider.notifier).updateGameList(gameList);
    }

    matches.clear();
    setState(() {});
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
    super.build(context);

    final searchString = ref.watch(searchMatchesProvider);
    final currentMatch = ref.watch(matchProvider);
    final currentGameList = ref.watch(gamelistProvider);

    if (currentGameList != null &&
        currentGameList.game_id == gameList?.game_id &&
        currentGameList.time_modified != gameList?.time_modified) {
      gameList = currentGameList;
    }

    if (currentMatch != null && currentMatch.game_id == game_id) {
      final matchIndex = this
          .matches
          .indexWhere((match) => match.match_id == currentMatch.match_id);

      if (matchIndex != -1) {
        final match = this.matches[matchIndex];
        if (match.match_id != null &&
            currentMatch.match_id != null &&
            match.match_id == currentMatch.match_id &&
            match.time_modified != currentMatch.time_modified) {
          this.matches[matchIndex] = currentMatch;
        }
      } else {
        this.matches.insert(0, currentMatch);
      }
    }

    final matches = searchString.isEmpty
        ? this.matches
        : this
            .matches
            .where((match) => ((match.players != null
                        ? getAllPlayersUsernames(
                                playersToUsersLocal(match.players!))
                            .toLowerCase()
                        : "")
                    .contains(searchString.toLowerCase()) ||
                (match.games ?? [])
                    .join("")
                    .toLowerCase()
                    .contains(searchString.toLowerCase())))
            .toList();

    return Scaffold(
      appBar: widget.type.isNotEmpty
          ? null
          : (isSearch
              ? AppSearchBar(
                  hint: "Search Matches",
                  controller: searchController,
                  onChanged: updateSearch,
                  onCloseSearch: stopSearch,
                )
              : AppAppBar(
                  middle: GestureDetector(
                    onTap: gameList?.time_end != null ? null : gotoGameProfile,
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
                                    : gameList?.game?.groupName != null
                                        ? gameList!.game!.groupName!
                                        : "",
                                style: TextStyle(
                                    fontSize: 18,
                                    color: tint,
                                    fontWeight: FontWeight.bold),
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
                      if (gameList?.time_end == null)
                        AppPopupMenuButton(
                            options: menuOptions,
                            onSelected: executeMenuOptions)
                    ],
                  ),
                )) as PreferredSizeWidget?,
      body: matches.isEmpty
          ? loading
              ? const LoadingView()
              : const EmptyListView(message: "No match")
          : Column(
              children: [
                if (gameList?.time_end != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                        color: lightestTint,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                        "You ${gameList?.game?.groupName != null ? "left" : "blocked"}",
                        style: context.bodySmall),
                  )
                ],
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (!loading &&
                          scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent &&
                          matches.isNotEmpty) {
                        final lastMatch = matches.last;
                        final time =
                            gameList?.time_start ?? gameList?.time_created;

                        if ((time != null &&
                                lastMatch.time_created!.toInt < time.toInt) &&
                            isConnectedToInternet &&
                            !loading &&
                            !reachedEnd) {
                          loadPreviousMatches(lastMatch.time_created!);
                        }
                      }
                      return false;
                    },
                    child: ListView.builder(
                        itemCount: matches.length + (loading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (loading && index == matches.length) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final match = matches[index];

                          return MatchListItem(
                            key: Key(match.match_id ?? "$index"),
                            position: index,
                            matches: matches,
                            groupName: game?.groupName,
                          );
                        }),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: widget.type.isNotEmpty
          ? null
          : AppButton(title: "Play", onPressed: playMatch),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
