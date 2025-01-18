import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/widgets/app_appbar.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../shared/utils/constants.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../theme/colors.dart';

import '../../game/providers/search_games_provider.dart';
import '../services.dart';
import '../widgets/game_item.dart';
import '../widgets/user_game_item.dart';

class UserGamesSelectionPage extends ConsumerStatefulWidget {
  final String? gameId;
  final List<String> games;

  // final List<UserGame> userGames;
  const UserGamesSelectionPage({super.key, this.gameId, required this.games});

  @override
  ConsumerState<UserGamesSelectionPage> createState() =>
      _UserGamesSelectionPageState();
}

class _UserGamesSelectionPageState extends ConsumerState<UserGamesSelectionPage>
    with SingleTickerProviderStateMixin {
  final searchController = TextEditingController();
  TabController? tabController;

  bool isSearch = false;
  bool saving = false;

  List<String> selectedGames = [];

  @override
  void initState() {
    super.initState();
    // getUserGamesMap();
    selectedGames = [...widget.games];
    tabController =
        TabController(length: allGameCategories.length, vsync: this);
  }

  @override
  void dispose() {
    tabController?.dispose();
    searchController.dispose();
    super.dispose();
  }

  // void getUserGamesMap() {
  //   for (int i = 0; i < games.length; i++) {
  //     final game = games[i];
  //     gamesMap[game] = true;
  //   }
  // }

  // void updateUserGame(UserGame userGame, String? ability) {
  //   ability ??= "";
  //   userGame.ability =
  //       userGame.ability.isNotEmpty && userGame.ability == ability
  //           ? ""
  //           : ability;
  //   gamesMap[userGame.name] = userGame;
  //   if (userGame.ability.isNotEmpty) {
  //     final index = widget.userGames
  //         .indexWhere((element) => element.name == userGame.name);
  //     if (index != -1) {
  //       widget.userGames[index] = userGame;
  //     } else {
  //       widget.userGames.add(userGame);
  //     }
  //   } else {
  //     widget.userGames.removeWhere((element) => element.name == userGame.name);
  //   }
  //   setState(() {});
  // }

  void updateGames(String game, bool? selected) {
    if (selected == null) return;
    if (selected) {
      selectedGames.add(game);
    } else {
      selectedGames.remove(game);
    }
    setState(() {});
  }

  void startSearch() {
    isSearch = true;
    setState(() {});
  }

  void updateSearch(String value) {
    ref
        .read(searchGamesProvider.notifier)
        .updateSearch(value.trim().toLowerCase());
  }

  void stopSearch() {
    ref.read(searchGamesProvider.notifier).updateSearch("");

    searchController.clear();
    isSearch = false;
    setState(() {});
  }

  void saveUserGames() async {
    saving = true;
    setState(() {});
    final time = timeNow;
    try {
      if (widget.gameId != null) {
        await updateGroupGames(widget.gameId!, selectedGames, time);
      } else {
        await updateUserGames(selectedGames, time);
      }
      if (!mounted) return;
      context.pop({"games": selectedGames, "time": time});
    } catch (e) {
      saving = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchString = ref.watch(searchGamesProvider);

    return PopScope(
      canPop: !isSearch,
      onPopInvoked: (pop) {
        if (pop) return;
        if (isSearch) {
          stopSearch();
        }
      },
      child: Scaffold(
        appBar: (isSearch
            ? AppSearchBar(
                hint: "Search games",
                controller: searchController,
                onChanged: updateSearch,
                onCloseSearch: stopSearch,
              )
            : AppAppBar(
                title: "${widget.gameId != null ? "Group" : "My"} Games",
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        onPressed: startSearch,
                        icon: const Icon(EvaIcons.search),
                        color: tint),
                  ],
                ),
              )) as PreferredSizeWidget?,
        body: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "NB: You free to play any game you like. This is just to tell people the kind of games you like to play",
                style: context.bodySmall
                    ?.copyWith(color: lighterTint, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
            // const SizedBox(height: 10),
            // Text(
            //   getGamesString(games),
            //   style: context.bodyMedium?.copyWith(color: lightTint),
            // ),
            // const SizedBox(height: 5),
            Center(
              child: TabBar(
                controller: tabController,
                padding: EdgeInsets.zero,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                dividerColor: transparent,
                tabs: List.generate(
                  allGameCategories.length,
                  (index) {
                    final tab = allGameCategories[index];
                    return Tab(text: tab, height: 35);
                  },
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: List.generate(allGameCategories.length, (index) {
                  final foundGames = index == 0
                      ? allBoardGames
                      : index == 1
                          ? allCardGames
                          : index == 2
                              ? allPuzzleGames
                              : allQuizGames;
                  final games = searchString.isEmpty
                      ? foundGames
                      : foundGames
                          .where((game) =>
                              game.toLowerCase().contains(searchString))
                          .toList();

                  return ListView.builder(
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];
                      return GameItem(
                        game: game,
                        selectedGames: selectedGames,
                        onChanged: (selected) => updateGames(game, selected),
                      );
                      // final userGame =
                      //     gamesMap[game] ?? UserGame(name: game, ability: "");
                      // return UserGameItem(
                      //   key: Key(userGame.name),
                      //   userGame: userGame,
                      //   onChanged: (ability) =>
                      //       updateUserGame(userGame, ability),
                      // );
                    },
                  );
                }),
              ),
            ),
            Center(
              child: AppButton(
                  title: saving ? "Saving" : "Save",
                  // wrapped: true,
                  loading: saving,
                  disabled: saving,
                  onPressed: saveUserGames),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
