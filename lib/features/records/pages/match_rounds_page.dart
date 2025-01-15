import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/features/records/widgets/match_record_item.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/models/models.dart';
import 'package:gamesarena/shared/views/loading_overlay.dart';
import '../../../shared/utils/utils.dart';
import '../../../shared/widgets/app_appbar.dart';
import '../../../shared/widgets/app_button.dart';

import '../../../theme/colors.dart';
import '../../game/pages/games_page.dart';
import '../../match/providers/match_provider.dart';
import '../../players/pages/players_selection_page.dart';
import '../models/match_round.dart';
import '../widgets/match_round_item.dart';

class MatchRoundsPage extends ConsumerStatefulWidget {
  final Match match;
  final MatchRecord record;
  final String? groupName;
  const MatchRoundsPage({
    super.key,
    required this.match,
    required this.record,
    this.groupName,
  });

  @override
  ConsumerState<MatchRoundsPage> createState() => _MatchRoundsPageState();
}

class _MatchRoundsPageState extends ConsumerState<MatchRoundsPage> {
  String name = "";
  late Match match;
  List<User> users = [];
  List<MatchRound> matchRounds = [];
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
    matchRounds = getMatchRecordRounds(widget.record);

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

  void gotoGame([String? game, int? recordId, int? roundId]) {
    gotoGamePage(context, game, match.game_id!, match.match_id!,
        match: match,
        users: users,
        recordId: recordId,
        roundId: roundId,
        isReplacement: false);
  }

  @override
  Widget build(BuildContext context) {
    final currentMatch = ref.watch(matchProvider);

    if (match.match_id != null &&
        currentMatch?.match_id != null &&
        match.match_id == currentMatch!.match_id &&
        match.time_modified != currentMatch.time_modified) {
      match = currentMatch;
      getDetails();
    }
    return Scaffold(
      appBar: const AppAppBar(title: "Match Rounds"),
      body: LoadingOverlay(
        loading: loading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //MatchListItem(matches: [match], position: 0, isMatchRecords: true),
            // MatchRecordItem(
            //     match: match,
            //     record: widget.record,
            //     index: widget.record.id,
            //     showPlayers: false,
            //     onWatchPressed: () => gotoGame(widget.record.id, 0)),
            Expanded(
              child: ListView.builder(
                itemCount:
                    matchRounds.length + (matchRounds.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (matchRounds.isNotEmpty && index == matchRounds.length) {
                    return MatchRecordItem(
                        match: match,
                        record: widget.record,
                        index: widget.record.id,
                        onWatchPressed: () =>
                            gotoGame(widget.record.game, widget.record.id, 0));
                  }
                  final round = matchRounds[index];

                  return MatchRoundItem(
                      match: match,
                      round: round,
                      index: index,
                      onWatchPressed: () => gotoGame(
                          widget.record.game, widget.record.id, index));
                },
              ),
            )
          ],
        ),
      ),
      // bottomNavigationBar: matchRounds.isEmpty
      //     ? null
      //     : AppButton(
      //         title: "Watch",
      //         onPressed: () => gotoGame(null, widget.record.id, 0),
      //       ),
      bottomNavigationBar: match.players == null
          ? null
          : Row(
              children: [
                if (match.time_end != null ||
                    (match.time_end == null &&
                        (match.available_players != null &&
                            !match.available_players!.contains(myId))))
                  Expanded(
                    child: AppButton(
                        title: "Watch",
                        bgColor: lightestTint,
                        color: tint,
                        onPressed: () {
                          gotoGame(null, widget.record.id, 0);
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
