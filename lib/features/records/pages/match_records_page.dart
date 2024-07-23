import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import '../../user/widgets/user_item.dart';
import '../../../shared/services.dart';
import 'package:gamesarena/features/game/models/match.dart';
import '../models/match_record.dart';
import '../../user/models/user.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/utils.dart';

class MatchRecordsPage extends StatefulWidget {
  final Match match;
  final List<User> users;
  final List<String> players;
  final List<MatchRecord> matchRecords;
  final int duration;
  const MatchRecordsPage({
    super.key,
    required this.match,
    required this.users,
    required this.players,
    required this.matchRecords,
    required this.duration,
  });

  @override
  State<MatchRecordsPage> createState() => _MatchRecordsPageState();
}

class _MatchRecordsPageState extends State<MatchRecordsPage> {
  String name = "";
  late Match match;
  List<User> users = [];
  List<String> players = [];
  List<MatchRecord> matchRecords = [];

  @override
  void initState() {
    super.initState();
    match = widget.match;
    matchRecords = widget.matchRecords;
    users = widget.users;
    players = widget.players;
  }

  String getMatchMessage() {
    String matchMessage = "";
    if (match.time_start != null && match.time_start != "") {
      matchMessage = "${matchRecords.last.game} - ${matchRecords.length} games";
    } else {
      matchMessage = "Missed match";
    }
    return matchMessage;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text("Match Records"),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        match.creator_id != myId ? "Incoming" : "Outgoing",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        match.time_created?.time ?? "",
                        style: TextStyle(
                            fontSize: 14,
                            color: darkMode ? lightWhite : lighterBlack),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            match.creator_id == myId
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: match.creator_id != myId &&
                                    (match.time_start == "" ||
                                        match.time_start == null)
                                ? Colors.red
                                : Colors.blue,
                            size: 15,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            getMatchMessage(),
                            style: TextStyle(
                                fontSize: 16,
                                color: match.creator_id != myId &&
                                        (match.time_start == "" ||
                                            match.time_start == null)
                                    ? Colors.red
                                    : null),
                          ),
                        ],
                      ),
                      if (widget.duration != 0) ...[
                        Text(
                          widget.duration.toDurationString(false),
                          style: TextStyle(
                              fontSize: 14,
                              color: darkMode
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.6)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (matchRecords.isNotEmpty) ...[
                  SizedBox(
                      height: 100,
                      child: Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(users.length, (index) {
                        final user = users[index];
                        return SizedBox(
                            width: context.screenWidth / players.length,
                            child: UserItem(
                                user: user, type: "", onPressed: () {}));
                      }))),
                  Expanded(
                      child: ListView.builder(
                          itemCount: matchRecords.length,
                          itemBuilder: (context, index) {
                            final record = matchRecords[index];
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (index == 0 ||
                                    record.game !=
                                        matchRecords[index - 1].game) ...[
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(
                                      record.game,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children:
                                        List.generate(players.length, (index) {
                                      int score = 0;
                                      if (index == 0) {
                                        score = record.player1Score ?? 0;
                                      } else if (index == 1) {
                                        score = record.player2Score ?? 0;
                                      } else if (index == 2) {
                                        score = record.player3Score ?? 0;
                                      } else if (index == 3) {
                                        score = record.player4Score ?? 0;
                                      }
                                      return SizedBox(
                                          width: context.screenWidth /
                                              players.length,
                                          child: Text(
                                            "$score",
                                            textAlign: TextAlign.center,
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ));
                                    }),
                                  ),
                                ),
                              ],
                            );
                          })),
                ],
              ],
            )));
  }
}
