import 'package:gamesarena/shared/services.dart';
import 'package:gamesarena/shared/widgets/action_button.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/features/records/pages/game_records_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../game/services.dart';
import '../../game/widgets/game_list_item.dart';
import '../../../shared/models/models.dart';
import '../../onboarding/pages/auth_page.dart';
import '../../onboarding/pages/login_page.dart';

class MatchesPage extends StatefulWidget {
  final VoidCallback playGameCallback;
  const MatchesPage({super.key, required this.playGameCallback});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  List<GameList> gameLists = [];
  late Stream<List<GameList>> gameListStream;
  @override
  void initState() {
    super.initState();
    gameListStream = readGameLists();
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
                builder: (context) => const AuthPage(),
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
                    wrap: true,
                  )
                ],
              );
            }
            gameLists.sortList((gameList) => gameList.time, true);
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
