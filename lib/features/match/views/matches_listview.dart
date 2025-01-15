// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/records/services.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/views/empty_listview.dart';
import 'package:gamesarena/shared/views/loading_view.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../shared/utils/utils.dart';
import '../../game/models/match.dart';
import '../widgets/match_list_item.dart';

class MatchesListView extends StatefulWidget {
  final String gameId;
  final String type;
  const MatchesListView({
    super.key,
    required this.type,
    required this.gameId,
  });

  @override
  State<MatchesListView> createState() => _MatchesListViewState();
}

class _MatchesListViewState extends State<MatchesListView>
    with AutomaticKeepAliveClientMixin {
  List<Match> matches = [];
  bool reachedEnd = false;
  bool loading = false;
  int limit = 10;
  late Box<String> matchesBox;
  late Box<String> gameListsBox;
  @override
  void initState() {
    super.initState();
    matchesBox = Hive.box<String>("matches");
    gameListsBox = Hive.box<String>("gamelists");
    //readStoredMatches();
    readMatches();
  }

  void readStoredMatches() {
    final allMatches = matchesBox.values.map((map) => Match.fromJson(map));

    switch (widget.type) {
      case "play":
        matches = allMatches
            .where((match) =>
                match.game_id == widget.gameId &&
                match.outcome != "" &&
                match.players!.contains(myId))
            .toList();
        break;
      case "win":
        matches = allMatches
            .where((match) =>
                match.game_id == widget.gameId &&
                match.outcome == "win" &&
                match.winners!.contains(myId))
            .toList();
        break;

      case "draw":
        matches = allMatches
            .where((match) =>
                match.game_id == widget.gameId &&
                match.outcome == "draw" &&
                match.others!.contains(myId))
            .toList();
        break;

      case "loss":
        matches = allMatches
            .where((match) =>
                match.game_id == widget.gameId &&
                match.outcome == "win" &&
                match.others!.contains(myId))
            .toList();
        break;

      case "incomplete":
        matches = allMatches
            .where((match) =>
                match.game_id == widget.gameId &&
                match.outcome != "" &&
                match.time_start != null &&
                match.time_end == null &&
                match.players!.contains(myId))
            .toList();
        break;

      case "missed":
        matches = allMatches
            .where((match) =>
                match.game_id == widget.gameId &&
                match.outcome == "" &&
                match.time_start == null &&
                match.players!.contains(myId))
            .toList();
        break;
    }

    matches.sortList((match) => match.time_created, true);
  }

  void readMatches() async {
    // print("reachedEnd = $reachedEnd, loading = $loading");
    print("readMatches");

    if (reachedEnd || loading || !mounted) return;

    loading = true;

    //setState(() {});
    try {
      final newMatches = await getPlayedMatches(widget.gameId,
          type: widget.type,
          lastTime: matches.lastOrNull?.time_created,
          limit: limit);
      print("newMatches = ${newMatches.length}, limit = $limit");
      if (!reachedEnd && newMatches.length < limit) {
        reachedEnd = true;
      }
      matches.addAll(newMatches);
    } catch (e) {
      print("e = $e");
    }
    loading = false;

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (matches.isEmpty) {
      if (loading) {
        return const LoadingView();
      }
      return const EmptyListView(message: "No match");
    }
    return ListView.builder(
      itemCount: matches.length + (loading ? 1 : 0),
      itemBuilder: (context, index) {
        print("reachedEnd = $reachedEnd, loading = $loading");

        if (index == matches.length - 1 && !reachedEnd && !loading) {
          readMatches();
        }
        if (loading && index == matches.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final match = matches[index];
        return MatchListItem(
            key: Key(match.match_id ?? "$index"),
            position: index,
            matches: matches);
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
