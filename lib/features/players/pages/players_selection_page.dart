import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/features/records/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/records/pages/game_records_page.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/utils/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../shared/extensions/special_context_extensions.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/views/loading_overlay.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../contact/pages/findorinvite_player_page.dart';
import '../../game/models/player.dart';
import '../../game/services.dart';
import '../../records/widgets/player_item.dart';
import '../../user/services.dart';
import '../../user/widgets/user_item.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../theme/colors.dart';
import '../providers/search_players_provider.dart';

class PlayersSelectionPage extends ConsumerStatefulWidget {
  final String type;
  final String? gameId;
  final String? groupName;
  final String? game;
  final List<Player>? players;
  const PlayersSelectionPage(
      {super.key,
      required this.type,
      this.gameId,
      this.groupName,
      this.game,
      this.players});

  @override
  ConsumerState<PlayersSelectionPage> createState() =>
      _PlayersSelectionPageState();
}

class _PlayersSelectionPageState extends ConsumerState<PlayersSelectionPage> {
  String type = "";
  String searchString = "";
  String? gameId;
  String? game;
  bool loading = true, reachedEnd = false;
  bool isSearch = false;

  TextEditingController searchController = TextEditingController();
  List<User> prevUsers = [], users = [], selectedUsers = [];
  int maxPlayers = 0;
  int minPlayers = 0;

  List<Player> checkedPlayers = [];

  @override
  void initState() {
    super.initState();
    type = widget.type;
    game = widget.game;
    gameId = widget.gameId;
    minPlayers = 2;
    if (type == "group") {
      maxPlayers = 100;
    } else if (game == null ||
        game == "Ludo" ||
        game == "Whot" ||
        game!.isPuzzle ||
        game!.isQuiz) {
      maxPlayers = 4;
    } else {
      maxPlayers = 2;
    }
    readUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<List<User>> playersToUsers(List<Player> players) async {
    List<User> users = [];
    for (int i = 0; i < players.length; i++) {
      final player = players[i];
      final user = await getUser(player.id);
      if (user != null) {
        users.add(user.copyWith());
      }
    }
    return users;
  }

  Future readPlayers([bool isMore = false]) async {
    loading = true;
    setState(() {});

    List<Player> players = [];

    if (widget.players == null || widget.players!.isEmpty) {
      List<Player> foundPlayers = [];

      if (gameId != null && gameId != "") {
        if (isMore) {
          foundPlayers =
              await getPlayers(gameId!, endTime: players.lastOrNull?.time);
          players.addAll(foundPlayers);
          if (foundPlayers.length < 10) reachedEnd = true;
        } else {
          foundPlayers =
              await getPlayers(gameId!, startTime: players.firstOrNull?.time);
          players.insertAll(0, foundPlayers);
          if (players.length < 10) reachedEnd = true;
        }
      } else {
        final playersBox = Hive.box<String>("players");

        if (isMore) {
          foundPlayers = await getMyPlayers(endTime: players.lastOrNull?.time);
          players.addAll(foundPlayers);
          if (foundPlayers.length < 10) reachedEnd = true;
        } else {
          //if (players.isEmpty) {
          players = playersBox.values.map((e) => Player.fromJson(e)).toList();
          players.sortList((player) => player.time, true);
          // }
          foundPlayers =
              await getMyPlayers(startTime: players.firstOrNull?.time);
          players.insertAll(0, foundPlayers);
          if (players.length < 10) reachedEnd = true;
        }
        for (int i = 0; i < foundPlayers.length; i++) {
          final player = foundPlayers[i];
          playersBox.put(player.id, player.toJson());
        }
      }
    } else {
      players = widget.players!;
    }

    final users = await playersToUsers(players);
    prevUsers.addAll(users);
    this.users.addAll(users);
    // if (searchString != "") {
    //   searchRecords();
    // }
    if (!mounted) return;
    loading = false;
    setState(() {});
  }

  void readUsers() async {
    final user = await getUser(myId);
    if (user != null) {
      selectedUsers.add(user);
    }
    if (!mounted) return;
    readPlayers();
  }

  void searchRecords() {
    if (searchString != "") {
      if (prevUsers.isNotEmpty) {
        final searchedUsers = prevUsers
            .where((element) => element.username.contains(searchString))
            .toList();
        users = searchedUsers;
      }
    } else {
      users = prevUsers;
    }
    setState(() {});
  }

  void searchForUser() async {
    String value = searchController.text.toLowerCase();
    if (value.isEmpty) {
      return;
    }
    String type = "";
    if (value.isValidEmail()) {
      type = "email";
    } else if (value.isOnlyNumber()) {
      type = "phone";
      value = value.toValidNumber() ?? "";
      if (value.isEmpty) return;
    } else {
      type = "username";
    }
    if (type.isEmpty) {
      showErrorToast("Invalid username, email or phone");

      return;
    }

    final searchedUsers = await searchUser(type, value);
    if (searchedUsers.isNotEmpty) {
      for (int i = 0; i < searchedUsers.length; i++) {
        final user = searchedUsers[i];
        if (user.user_id == myId) {
          showToast("You are already a players in the game");
          continue;
        }
        final index =
            prevUsers.indexWhere((element) => element.user_id == user.user_id);
        if (index != -1) {
          final prevUser = prevUsers[index];
          user.checked = prevUser.checked;
          prevUsers.removeWhere((element) => element.user_id == user.user_id);
        }
        prevUsers.insert(0, user);
      }
      searchController.clear();
    } else {
      showErrorToast("No user found. Check that the $type is correct");
    }
    users = prevUsers;
    setState(() {});
  }

  Future<bool> isAPlayerInGroup(String playerId) async {
    if (widget.gameId == null) return false;
    if (checkedPlayers.indexWhere((element) => element.id == playerId) != -1) {
      return true;
    }

    final player = await getPlayer(widget.gameId!, playerId);
    if (player != null) checkedPlayers.add(player);
    return player != null;
  }

  void startSearch() {
    isSearch = true;
    setState(() {});
  }

  void updateSearch(String value) {
    ref
        .read(searchPlayersProvider.notifier)
        .updateSearch(value.trim().toLowerCase());
  }

  void stopSearch() {
    ref.read(searchPlayersProvider.notifier).updateSearch("");

    searchController.clear();
    isSearch = false;
    setState(() {});
  }

  Future<bool> checkIfAnyPlayerIsPlayingMatch() async {
    List<User> users = [];

    bool isPlaying = false;
    for (int i = 0; i < selectedUsers.length; i++) {
      final user = selectedUsers[i];
      if (user.user_id == myId) continue;
      final playing = await isPlayingAMatch(user.user_id);
      if (playing) {
        users.add(user);
        if (!isPlaying) isPlaying = true;
      }
    }
    if (users.isNotEmpty) {
      showErrorToast(
          "${users.toStringWithCommaandAnd((t) => t.username)} ${users.length > 1 ? "are" : "is"} currently in another match");
      selectedUsers.removeWhere((element) => users.contains(element));
    }
    setState(() {});
    return isPlaying;
  }

  void executeAction() async {
    if (selectedUsers.length < minPlayers) {
      showErrorToast(
          "There should be at least $minPlayers players in a ${game != null ? "$game " : ""}game");
      return;
    } else if (selectedUsers.length > maxPlayers) {
      showErrorToast(
          "There can only be $maxPlayers number of players in a ${game != null ? "$game " : ""}game");
      return;
    }
    if (type == "group" && widget.gameId == null) {
      final finish = await (Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => NewGroupPage(users: selectedUsers)))) as bool?;
      if (finish != null) {
        if (!mounted) return;
        Navigator.pop(context);
      }
    } else {
      // final isPlaying = await checkIfAnyPlayerIsPlayingMatch();
      // if (isPlaying || !mounted) return;
      if (!mounted) return;
      Navigator.pop(context, selectedUsers.map((e) => e.user_id).toList());
    }
  }

  void gotoNewGroup() {
    context.pushReplacement(const PlayersSelectionPage(type: "group"));
  }

  void gotoInviteContact() {
    context.pushTo(const FindOrInvitePlayersPage());
  }

  @override
  Widget build(BuildContext context) {
    final searchString = ref.watch(searchPlayersProvider);

    final users = this
        .users
        .where((user) =>
            user.username.toLowerCase().contains(searchString) ||
            user.email.toLowerCase().contains(searchString) ||
            user.phone.toLowerCase().contains(searchString))
        .toList();

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
                hint: "Search username, email or phone",
                controller: searchController,
                onChanged: updateSearch,
                onCloseSearch: stopSearch,
                onPressedSearch: searchForUser,
              )
            : AppAppBar(
                title: type == "group"
                    ? widget.groupName != null
                        ? widget.groupName!
                        : "New Group"
                    : "${game ?? "New"} game",
                subtitle: type == "group"
                    ? "Add Players"
                    : "Select Player${maxPlayers == 2 ? "" : "s"}${widget.groupName != null ? " from ${widget.groupName}" : ""}",
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        onPressed: startSearch,
                        icon: const Icon(EvaIcons.search),
                        color: tint),
                    if (isAndroidAndIos)
                      IconButton(
                        onPressed: gotoInviteContact,
                        icon: const Icon(EvaIcons.person_add_outline),
                        color: tint,
                      ),
                    if (type != "group")
                      IconButton(
                        onPressed: gotoNewGroup,
                        icon: SizedBox(
                          height: 30,
                          width: 30,
                          child: Stack(
                            // alignment: Alignment.topRight,
                            children: [
                              const Positioned(
                                  left: 0,
                                  bottom: 0,
                                  child: Icon(OctIcons.people, size: 24)),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Text("+",
                                    style: context.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              )
                            ],
                          ),
                        ),
                        color: tint,
                      ),
                  ],
                ),
              )) as PreferredSizeWidget?,
        body: LoadingOverlay(
          loading: loading && users.isEmpty,
          child: SizedBox.expand(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    "Players: ${selectedUsers.length} / $maxPlayers",
                    style: context.bodyMedium,
                  ),
                ),
                if (selectedUsers.isNotEmpty) ...[
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                        primary: true,
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedUsers.length,
                        itemBuilder: (context, index) {
                          final user = selectedUsers[index];
                          return UserItem(
                            key: Key(user.user_id),
                            user: user,
                            type: "select",
                            onPressed: () async {
                              if (user.user_id == myId) return;
                              final i = users.indexWhere(
                                  (element) => user.user_id == element.user_id);
                              if (i != -1) {
                                final user = users[i];
                                user.checked = false;
                              }
                              setState(() {
                                selectedUsers.removeAt(index);
                              });
                            },
                          );
                        }),
                  ),
                ],
                Expanded(
                  child: ListView.builder(
                      itemCount:
                          users.length + (users.isNotEmpty && loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        if (index == users.length - 1 &&
                            !reachedEnd &&
                            !loading) {
                          readPlayers(true);
                        }
                        if (loading && index == users.length) {
                          return const CircularProgressIndicator();
                        }
                        return PlayerItem(
                          key: Key(user.user_id),
                          user: user,
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            if (type == "oneonone") {
                              Navigator.of(context)
                                  .pushReplacement(MaterialPageRoute(
                                      builder: (context) => GameRecordsPage(
                                            id: user.user_id,
                                            type: "",
                                            game_id: "",
                                          )));
                            } else {
                              final selIndex = selectedUsers.isEmpty
                                  ? -1
                                  : selectedUsers.indexWhere((element) =>
                                      user.user_id == element.user_id);
                              if (selIndex == -1) {
                                if (widget.gameId != null &&
                                    widget.type == "group" &&
                                    (await isAPlayerInGroup(user.user_id))) {
                                  showErrorToast(
                                      "${user.username} is already a player in the group");
                                  return;
                                }
                                if (selectedUsers.length == maxPlayers) {
                                  showErrorToast(
                                      "There can only be $maxPlayers number of Players in $game game");
                                  return;
                                }
                                selectedUsers.add(user);
                                user.checked = true;
                              } else {
                                selectedUsers.removeAt(selIndex);
                                user.checked = false;
                              }
                            }
                            setState(() {});
                          },
                        );
                        // return UserListItem(
                        //   key: Key(user.user_id),
                        //   user: user,
                        //   onPressed: () async {
                        //     FocusScope.of(context).unfocus();
                        //     if (type == "oneonone") {
                        //       Navigator.of(context)
                        //           .pushReplacement(MaterialPageRoute(
                        //               builder: (context) => GameRecordsPage(
                        //                     id: user.user_id,
                        //                     type: "",
                        //                     game_id: "",
                        //                   )));
                        //     } else {
                        //       final selIndex = selectedUsers.isEmpty
                        //           ? -1
                        //           : selectedUsers.indexWhere((element) =>
                        //               user.user_id == element.user_id);
                        //       if (selIndex == -1) {
                        //         if (widget.gameId != null &&
                        //             widget.type == "group" &&
                        //             (await isAPlayerInGroup(user.user_id))) {
                        //           showErrorToast(
                        //               "${user.username} is already a player in the group");
                        //           return;
                        //         }
                        //         if (selectedUsers.length == maxPlayers) {
                        //           showErrorToast(
                        //               "There can only be $maxPlayers number of Players in $game game");
                        //           return;
                        //         }
                        //         selectedUsers.add(user);
                        //         user.checked = true;
                        //       } else {
                        //         selectedUsers.removeAt(selIndex);
                        //         user.checked = false;
                        //       }
                        //     }
                        //     setState(() {});
                        //   },
                        // );
                      }),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: loading
            ? null
            : AppButton(
                title: type == "group" || game == null ? "Next" : "Play",
                onPressed: executeAction),
      ),
    );
  }
}
