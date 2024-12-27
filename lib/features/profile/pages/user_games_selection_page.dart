import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/records/utils/utils.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/widgets/app_appbar.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../shared/utils/constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../theme/colors.dart';
import '../../home/providers/search_games_provider.dart';
import '../../user/models/user_game.dart';
import '../services.dart';
import '../widgets/user_game_item.dart';

class UserGamesSelectionPage extends ConsumerStatefulWidget {
  final String? gameId;
  final List<UserGame> userGames;
  const UserGamesSelectionPage(
      {super.key, this.gameId, required this.userGames});

  @override
  ConsumerState<UserGamesSelectionPage> createState() =>
      _UserGamesSelectionPageState();
}

class _UserGamesSelectionPageState extends ConsumerState<UserGamesSelectionPage>
    with SingleTickerProviderStateMixin {
  Map<String, UserGame> userGamesMap = {};
  final searchController = TextEditingController();
  TabController? tabController;

  bool isSearch = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    getUserGamesMap();
    tabController =
        TabController(length: allGameCategories.length, vsync: this);
  }

  @override
  void dispose() {
    tabController?.dispose();
    searchController.dispose();
    super.dispose();
  }

  void getUserGamesMap() {
    for (int i = 0; i < widget.userGames.length; i++) {
      final userGame = widget.userGames[i];
      userGamesMap[userGame.name] = userGame;
    }
  }

  void updateUserGame(UserGame userGame, String? ability) {
    ability ??= "";
    userGame.ability =
        userGame.ability.isNotEmpty && userGame.ability == ability
            ? ""
            : ability;
    userGamesMap[userGame.name] = userGame;
    if (userGame.ability.isNotEmpty) {
      final index = widget.userGames
          .indexWhere((element) => element.name == userGame.name);
      if (index != -1) {
        widget.userGames[index] = userGame;
      } else {
        widget.userGames.add(userGame);
      }
    } else {
      widget.userGames.removeWhere((element) => element.name == userGame.name);
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
    try {
      if (widget.gameId != null) {
        await updateGroupUserGames(widget.gameId!, widget.userGames);
      } else {
        await updateUserGames(widget.userGames);
      }
      if (!mounted) return;
      context.pop(widget.userGames);
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
                      onPressed: () {
                        startSearch();
                      },
                      icon: const Icon(EvaIcons.search),
                      color: tint,
                    ),
                  ],
                ),
              )) as PreferredSizeWidget?,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                "NB: You free to play any game you like. This is just to tell people the kind of games you can play and how good you are in them.\nTap or UnTap if you want to add or remove a game from the list",
                style: context.bodySmall
                    ?.copyWith(color: lighterTint, fontSize: 10),
              ),
              const SizedBox(height: 10),
              Text(
                getUserGamesString(widget.userGames),
                style: context.bodyMedium?.copyWith(color: lightTint),
              ),
              const SizedBox(height: 5),
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
                      return Tab(text: tab);
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
                    final games = foundGames
                        .where(
                            (game) => game.toLowerCase().contains(searchString))
                        .toList();

                    return ListView.builder(
                      itemCount: games.length,
                      itemBuilder: (context, index) {
                        final game = games[index];
                        final userGame = userGamesMap[game] ??
                            UserGame(name: game, ability: "");
                        return UserGameItem(
                          key: Key(userGame.name),
                          userGame: userGame,
                          onChanged: (ability) =>
                              updateUserGame(userGame, ability),
                        );
                      },
                    );
                  }),
                ),
              ),
              Center(
                child: AppButton(
                    title: saving ? "Saving" : "Save",
                    wrapped: true,
                    loading: saving,
                    disabled: saving,
                    onPressed: saveUserGames),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
