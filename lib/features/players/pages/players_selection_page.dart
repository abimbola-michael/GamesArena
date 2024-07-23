import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/records/pages/game_records_page.dart';
import 'package:gamesarena/features/games/pages.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../shared/utils/utils.dart';
import '../../game/services.dart';
import '../../user/services.dart';
import '../../user/widgets/user_item.dart';
import '../../user/widgets/user_list_item.dart';
import '../../../shared/models/models.dart';
import '../../game/models/player.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../theme/colors.dart';

class OfflinePlayersSelectionPage extends StatefulWidget {
  const OfflinePlayersSelectionPage({super.key});

  @override
  State<OfflinePlayersSelectionPage> createState() =>
      _OfflinePlayersSelectionPageState();
}

class _OfflinePlayersSelectionPageState
    extends State<OfflinePlayersSelectionPage> {
  int playersSize = 2;
  List<int> sizes = [2, 4];
  int selected = 0;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text("Select Players"),
            ),
            body: SingleChildScrollView(
              primary: true,
              scrollDirection: Axis.vertical,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "How Many Players",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(sizes.length, (index) {
                            return GestureDetector(
                              onTap: () {
                                selected = index;
                                playersSize = sizes[index];
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: selected == index
                                        ? Colors.blue
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  sizes[index].toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          })),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ActionButton("Play Game", onPressed: () {
                      Navigator.of(context).pop(playersSize);
                    }, height: 50)
                  ]),
            )));
  }
}

class OnlinePlayersSelectionPage extends StatefulWidget {
  final String type;
  final String? group_id;
  final String? game;
  const OnlinePlayersSelectionPage(
      {super.key, required this.type, this.group_id, this.game});

  @override
  State<OnlinePlayersSelectionPage> createState() =>
      _OnlinePlayersSelectionPageState();
}

class _OnlinePlayersSelectionPageState
    extends State<OnlinePlayersSelectionPage> {
  String type = "";
  String searchString = "";
  String? group_id;
  String? game;
  bool creating = false, loading = true;
  TextEditingController controller = TextEditingController();
  List<User> prevUsers = [], users = [], selectedUsers = [];
  int maxPlayers = 0;

  @override
  void initState() {
    super.initState();
    type = widget.type;
    game = widget.game;
    group_id = widget.group_id;
    if (game == "Ludo" || game == "Whot") {
      maxPlayers = 4;
    } else {
      maxPlayers = 2;
    }
    readUsers();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              "${type == "group" ? "Add" : type == "oneonone" ? "Search" : "Select"}  Player${maxPlayers == 2 ? "" : "s"}"),
        ),
        body: creating || loading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        loading ? "Loading Players" : "Creating game...",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              )
            : SizedBox.expand(
                child: SingleChildScrollView(
                  primary: true,
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: TextField(
                                  controller: controller,
                                  onChanged: (text) {
                                    searchString = text;
                                    searchRecords();
                                  },
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide:
                                              BorderSide(color: lightTint)),
                                      hintText:
                                          "Enter username, email or phone"),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                searchForUser();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(10)),
                                alignment: Alignment.center,
                                height: 50,
                                width: 50,
                                child: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      if (type == "") ...[
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            "Players: ${selectedUsers.length} / $maxPlayers",
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                      if (selectedUsers.isNotEmpty && type == "") ...[
                        SizedBox(
                          height: 100,
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
                                  onPressed: () {
                                    final i = users.indexWhere((element) =>
                                        user.user_id == element.user_id);
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
                      ListView.builder(
                          shrinkWrap: true,
                          primary: false,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return UserListItem(
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
                                    if (selectedUsers.length == maxPlayers) {
                                      Fluttertoast.showToast(
                                          msg:
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
                          }),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: creating || type != ""
            ? null
            : ActionButton(
                type == "group" ? "Next" : "Play",
                onPressed: () async {
                  if (type == "group") {
                    final finish =
                        await (Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => NewGroupPage(
                                  users: selectedUsers,
                                )))) as bool?;
                    if (finish != null) {
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    }
                  } else {
                    if (selectedUsers.length == 1) {
                      Fluttertoast.showToast(
                          msg: "Tap to select a player to play with");
                    } else if (selectedUsers.length > maxPlayers) {
                      Fluttertoast.showToast(
                          msg:
                              "There can only be $maxPlayers number of Players in $game game");
                    } else {
                      Navigator.pop(context,
                          selectedUsers.map((e) => e.user_id).toList());
                    }
                  }
                },
                height: 50,
                half: true,
              ),
      ),
    );
  }

  Future<List<User>> playersToUsers(List<Player> players) async {
    List<User> users = [];
    if (players.isNotEmpty) {
      for (int i = 0; i < players.length; i++) {
        final player = players[i];
        final user = await getUser(player.id);
        if (user != null) {
          users.add(user);
        }
      }
    }
    return users;
  }

  void readUsers() async {
    final user = await getUser(myId);
    if (user != null) {
      selectedUsers.add(user);
    }
    if (!mounted) return;
    setState(() {});
    List<Player> players = [];
    if (group_id != null && group_id != "") {
      players = await readGroupPlayers(group_id!);
    } else {
      players = await readPlayers();
    }
    final users = await playersToUsers(players);
    prevUsers.addAll(users);
    this.users.addAll(users);
    if (searchString != "") {
      searchRecords();
    }
    if (!mounted) return;
    loading = false;
    setState(() {});
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
    String value = controller.text.toLowerCase();
    String type = "";
    if (value.isValidEmail()) {
      type = "email";
    } else if (value.isOnlyNumber()) {
      type = "phone";
    } else {
      type = "username";
    }
    final searchedUsers = await searchUser(type, value);
    if (searchedUsers.isNotEmpty) {
      for (int i = 0; i < searchedUsers.length; i++) {
        final user = searchedUsers[i];
        if (user.user_id == myId) {
          Fluttertoast.showToast(msg: "You are already a player in the game");
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
      controller.clear();
    } else {
      Fluttertoast.showToast(
          msg: "No user found. Check that the $type is correct");
    }
    users = prevUsers;
    setState(() {});
  }
}
