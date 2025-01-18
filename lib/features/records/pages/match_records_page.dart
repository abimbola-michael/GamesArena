import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/features/match/widgets/match_list_item.dart';
import 'package:gamesarena/features/records/models/match_round.dart';
import 'package:gamesarena/features/records/pages/match_rounds_page.dart';
import 'package:gamesarena/features/records/widgets/match_record_item.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/models/models.dart';
import 'package:gamesarena/shared/views/loading_overlay.dart';
import 'package:gamesarena/theme/colors.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../game/pages/games_page.dart';

import '../../match/providers/match_provider.dart';
import '../../players/pages/players_selection_page.dart';
import '../widgets/match_overall_record_item.dart';

class MatchRecordsPage extends ConsumerStatefulWidget {
  final Match match;
  final String? groupName;

  const MatchRecordsPage({
    super.key,
    required this.match,
    this.groupName,
  });

  @override
  ConsumerState<MatchRecordsPage> createState() => _MatchRecordsPageState();
}

class _MatchRecordsPageState extends ConsumerState<MatchRecordsPage> {
  late Match match;
  List<User> users = [];
  List<MatchRecord> matchRecords = [];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    match = widget.match;
    getDetails();
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

  void playMatch() {
    if (match.players == null) return;

    if (match.players!.contains(myId)) {
      context.pushTo(GamesPage(
          gameId: match.game_id,
          players: match.players,
          groupName: widget.groupName));
      return;
    }

    context.pushTo(PlayersSelectionPage(
      type: "user",
      gameId: match.game_id,
      playerIds: match.players!,
      groupName: widget.groupName,
    ));
  }

  void gotoGame([String? game, int? recordId, int? roundId]) async {
    gotoGamePage(context, game, match.game_id!, match.match_id!,
        match: match,
        users: users,
        recordId: recordId,
        roundId: roundId,
        isReplacement: false);
  }

  void gotoGameRounds(MatchRecord record) {
    context.pushTo(MatchRoundsPage(match: match, record: record));
  }

  @override
  Widget build(BuildContext context) {
    // print("match = $match");
    final currentMatch = ref.watch(matchProvider);

    if (match.match_id != null &&
        currentMatch?.match_id != null &&
        match.match_id == currentMatch!.match_id &&
        match.time_modified != currentMatch.time_modified) {
      match = currentMatch;
      getDetails();
    }
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
                itemCount: matchRecords.length + 1,
                itemBuilder: (context, index) {
                  if (index == matchRecords.length) {
                    return MatchOverallRecordItem(
                        match: match,
                        onWatchPressed: () {
                          if (matchRecords.isNotEmpty) {
                            gotoGame(widget.match.games?.firstOrNull ?? "",
                                index - 1, 0);
                          } else {
                            playMatch();
                          }
                        });
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
      bottomNavigationBar: match.players == null
          ? null
          : Row(
              children: [
                if (matchRecords.isNotEmpty &&
                    (match.time_end != null ||
                        (match.time_end == null &&
                            (match.available_players != null &&
                                !match.available_players!.contains(myId)))))
                  Expanded(
                    child: AppButton(
                        title: "Watch",
                        bgColor: lightestTint,
                        color: tint,
                        onPressed: () {
                          gotoGame();
                        }),
                  ),
                if (match.time_end == null &&
                    (match.available_players == null ||
                        match.available_players!.contains(myId)))
                  Expanded(
                    child: AppButton(title: "Continue", onPressed: gotoGame),
                  ),
                if (match.time_end != null)
                  Expanded(
                    child: AppButton(title: "Play", onPressed: playMatch),
                  ),
              ],
            ),
    );
  }
}
