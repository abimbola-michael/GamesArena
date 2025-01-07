import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/features/game/widgets/match_list_item.dart';
import 'package:gamesarena/features/records/models/match_round.dart';
import 'package:gamesarena/features/records/pages/match_rounds_page.dart';
import 'package:gamesarena/features/records/widgets/match_record_item.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/models/models.dart';
import 'package:gamesarena/shared/utils/constants.dart';
import 'package:gamesarena/shared/views/loading_overlay.dart';
import '../../../shared/widgets/action_button.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../user/widgets/user_item.dart';
import '../../../shared/services.dart';
import 'package:gamesarena/features/game/models/match.dart';
import '../models/match_record.dart';
import '../../user/models/user.dart';
import '../../../theme/colors.dart';
import '../../../shared/utils/utils.dart';
import '../widgets/match_overall_record_item.dart';

class MatchRecordsPage extends StatefulWidget {
  final Match match;

  const MatchRecordsPage({
    super.key,
    required this.match,
  });

  @override
  State<MatchRecordsPage> createState() => _MatchRecordsPageState();
}

class _MatchRecordsPageState extends State<MatchRecordsPage> {
  late Match match;
  List<User> users = [];
  List<MatchRecord> matchRecords = [];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    match = widget.match;
    getDetails();

    // final timeStart =
    //     (DateTime.now().millisecondsSinceEpoch - 10 * 1000).toString();
    // final timeEnd = (DateTime.now().millisecondsSinceEpoch).toString();
    // List<String> players = List.generate(4, (index) => "$index");
    // users = List.generate(
    //     4,
    //     (index) => User(
    //         user_id: "$index",
    //         username: "Player ${index + 1}",
    //         email: "",
    //         phone: "",
    //         token: "",
    //         time: "",
    //         last_seen: ""));
    // Map<String, dynamic> scores = {"0": 1, "1": 0, "2": 4, "3": 3};
    // match = Match(
    //     match_id: "1",
    //     game_id: "1",
    //     time_start: timeStart,
    //     time_end: timeEnd,
    //     game: chessGame,
    //     players: players,
    //     records: {
    //       "0": MatchRecord(
    //           id: 0,
    //           game: chessGame,
    //           time_start: timeStart,
    //           time_end: timeEnd,
    //           players: players,
    //           scores: scores,
    //           rounds: {
    //             "0": MatchRound(
    //                     id: 0,
    //                     game: chessGame,
    //                     time_start: timeStart,
    //                     time_end: timeEnd,
    //                     players: players,
    //                     scores: scores,
    //                     detailsLength: 0,
    //                     duration: 60)
    //                 .toMap()
    //           }).toMap(),
    //     });
    // match.users = users;
    // matchRecords = getMatchRecords(match);
  }

  Future getDetails() async {
    if (match.users == null && match.players != null) {
      loading = true;
      List<User> users = await playersToUsers(match.players!);
      match.users = users;
      loading = false;
    }

    users = match.users!;
    matchRecords = getMatchRecords(match);

    if (!mounted) return;

    setState(() {});
  }

  void gotoGame(String game, int recordId, int roundId) async {
    await gotoGamePage(context, game, match.game_id!, match.match_id!,
        match: match,
        users: users,
        recordId: recordId,
        roundId: roundId,
        isReplacement: false);
    setState(() {});
  }

  void gotoGameRounds(MatchRecord record) {
    context.pushTo(MatchRoundsPage(match: match, record: record));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: "Match Records"),
      body: LoadingOverlay(
        loading: loading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MatchListItem(matches: [match], position: 0, isMatchRecords: true),
            Expanded(
              child: ListView.builder(
                itemCount:
                    matchRecords.length + (matchRecords.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (matchRecords.isNotEmpty && index == matchRecords.length) {
                    return MatchOverallRecordItem(
                        match: match,
                        onWatchPressed: () => gotoGame(
                            widget.match.games?.firstOrNull ?? "",
                            index - 1,
                            0));
                  }
                  final record = matchRecords[index];
                  return MatchRecordItem(
                      match: match,
                      record: record,
                      index: index,
                      onPressed: () => gotoGameRounds(record),
                      onWatchPressed: () => gotoGame(record.game, index, 0));
                },
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: matchRecords.isEmpty
          ? null
          : AppButton(
              title: "Watch",
              onPressed: () =>
                  gotoGame(widget.match.games?.firstOrNull ?? "", 0, 0),
            ),
    );
  }
}
