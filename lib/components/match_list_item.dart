import 'package:gamesarena/blocs/firebase_service.dart';
import 'package:gamesarena/extensions/extensions.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../pages/match_records_page.dart';
import '../utils/utils.dart';

class MatchListItem extends StatefulWidget {
  final String gameId;
  final List<Match> matches;
  //final VoidCallback onPressed;
  final List<User> users;
  final int position;

  const MatchListItem({
    super.key,
    required this.gameId,
    required this.position,
    required this.matches,
    required this.users,
  });

  @override
  State<MatchListItem> createState() => _MatchListItemState();
}

class _MatchListItemState extends State<MatchListItem> {
  late Match match;
  late int position;
  String gameId = "";
  List<Match> matches = [];
  List<User> users = [];
  String name = "", myId = "";
  String matchMessage = "";
  int duration = 0;
  List<MatchRecord> matchRecords = [];
  List<String> players = [];

  FirebaseService fs = FirebaseService();
  @override
  void initState() {
    super.initState();
    myId = fs.myId;
    gameId = widget.gameId;
    users = widget.users;
    matches = widget.matches;
    position = widget.position;
    match = matches[position];
    if (match.player1 != null) {
      players.add(match.player1!);
    }
    if (match.player2 != null) {
      players.add(match.player2!);
    }
    if (match.player3 != null) {
      players.add(match.player3!);
    }
    if (match.player4 != null) {
      players.add(match.player4!);
    }
    getMatchDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (getDateVisibility()) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              match.time_created?.datetime.dateRange() ?? "",
              style: TextStyle(
                  fontSize: 14,
                  color: darkMode
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        ListTile(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return MatchRecordsPage(
                match: match,
                users: users,
                players: players,
                matchRecords: matchRecords,
                duration: duration,
              );
            }));
          },
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.creator_id != myId ? "Incoming" : "Outgoing",
                style: TextStyle(
                    fontSize: 16,
                    color: darkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                match.time_created?.time ?? "",
                style: TextStyle(
                    fontSize: 14,
                    color: darkMode
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.7)),
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
                            (match.time_start == "" || match.time_start == null)
                        ? Colors.red
                        : Colors.blue,
                    size: 15,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Text(
                    matchMessage,
                    style: TextStyle(
                        fontSize: 16,
                        color: match.creator_id != myId &&
                                (match.time_start == "" ||
                                    match.time_start == null)
                            ? Colors.red
                            : darkMode
                                ? Colors.white
                                : Colors.black),
                  ),
                ],
              ),
              if (duration != 0) ...[
                Text(
                  duration.toDurationString(false),
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
      ],
    );
  }

  bool getDateVisibility() {
    if (position == 0) return true;
    return matches[position - 1]
        .time_created!
        .datetime
        .showDate(match.time_created!.datetime);
  }

  void getMatchDetails() async {
    if (match.time_start != null && match.time_start != "") {
      matchRecords = await fs.getMatchRecords(gameId, match.match_id!);
      int durationCount = 0;
      for (int i = 0; i < matchRecords.length; i++) {
        final record = matchRecords[i];
        durationCount += record.duration ?? 0;
      }
      duration = durationCount;
      matchMessage = matchRecords.isEmpty
          ? "0 game"
          : "${matchRecords.last.game} - ${matchRecords.length} game${matchRecords.length == 1 ? "" : "s"}";
    } else {
      matchMessage = "Missed match";
    }
    setState(() {});
  }
}
