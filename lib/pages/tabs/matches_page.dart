import 'package:gamesarena/blocs/firebase_service.dart';
import 'package:gamesarena/components/action_button.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:gamesarena/pages/game_records_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../components/game_list_item.dart';
import '../../models/models.dart';
import '../login_page.dart';

class MatchesPage extends StatefulWidget {
  final VoidCallback playGameCallback;
  const MatchesPage({super.key, required this.playGameCallback});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  List<GameList> gameLists = [];
  FirebaseService fs = FirebaseService();
  late Stream<List<GameList>> gameListStream;
  @override
  void initState() {
    super.initState();
    gameListStream = fs.readGameLists();
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Login to Play Online Games"),
          ActionButton(
            "Login",
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const LoginPage(
                  login: true,
                ),
              ));
            },
            wrap: true,
          )
        ],
      );
    }
    return StreamBuilder<List<GameList>>(
        stream: gameListStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Something went wrong"),
            );
          }
          if (snapshot.hasData) {
            gameLists = snapshot.data!;
            if (gameLists.isEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No matches"),
                  ActionButton(
                    "Play Games",
                    onPressed: () {
                      widget.playGameCallback();
                    },
                    height: 50,
                    wrap: true,
                  )
                ],
              );
            } else {
              gameLists.sortList((gameList) => gameList.time, true);
            }
            return ListView.builder(
                itemCount: gameLists.length,
                itemBuilder: (context, index) {
                  final gameList = gameLists[index];
                  return GameListItem(
                    key: Key(gameList.game_id),
                    gameList: gameList,
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: ((context) => GameRecordsPage(
                              game_id: gameList.game_id, id: "", type: ""))));
                    },
                  );
                });
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }
}
