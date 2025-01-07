import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:gamesarena/features/game/utils.dart';
import 'package:gamesarena/features/game/widgets/match_list_item.dart';
import 'package:gamesarena/features/records/widgets/match_record_item.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/shared/models/models.dart';
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
import '../models/match_round.dart';
import '../widgets/match_round_item.dart';

class MatchRoundsPage extends StatefulWidget {
  final Match match;
  final MatchRecord record;

  const MatchRoundsPage({
    super.key,
    required this.match,
    required this.record,
  });

  @override
  State<MatchRoundsPage> createState() => _MatchRoundsPageState();
}

class _MatchRoundsPageState extends State<MatchRoundsPage> {
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

  void gotoGame(String game, int recordId, int roundId) {
    gotoGamePage(context, game, match.game_id!, match.match_id!,
        match: match,
        users: users,
        recordId: recordId,
        roundId: roundId,
        isReplacement: false);
  }

  @override
  Widget build(BuildContext context) {
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
      bottomNavigationBar: matchRounds.isEmpty
          ? null
          : AppButton(
              title: "Watch",
              onPressed: () => gotoGame(
                  widget.match.games?.firstOrNull ?? "", widget.record.id, 0),
            ),
    );
  }
}
