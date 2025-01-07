// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/features/records/services.dart';
import 'package:gamesarena/shared/views/empty_listview.dart';
import 'package:gamesarena/shared/views/loading_view.dart';
import '../../game/models/match.dart';
import '../../game/widgets/match_list_item.dart';

class MatchesListView extends StatefulWidget {
  final String gameId;
  final String? type;
  const MatchesListView({
    super.key,
    this.type,
    required this.gameId,
  });

  @override
  State<MatchesListView> createState() => _MatchesListViewState();
}

class _MatchesListViewState extends State<MatchesListView>
    with AutomaticKeepAliveClientMixin {
  List<Match> matches = [];
  bool hasMore = true;
  bool loading = false;
  int limit = 10;
  @override
  void initState() {
    super.initState();
    readMatches();
  }

  void readMatches() async {
    if (!hasMore || loading || !mounted) return;
    setState(() {
      loading = true;
    });
    try {
      final newMatches = await getPlayedMatches(widget.gameId,
          type: widget.type,
          lastTime: matches.lastOrNull?.time_created,
          limit: limit);
      if (hasMore && newMatches.length < limit) {
        hasMore = false;
      }
      matches.addAll(newMatches);
    } catch (e) {}

    if (!mounted) return;

    setState(() {
      loading = false;
    });
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
        if (index == matches.length - 1 && hasMore && !loading) {
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
