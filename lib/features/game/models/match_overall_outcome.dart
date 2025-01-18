// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class MatchOverallOutcome {
  List<int> scores;
  List<List<String>> games;

  MatchOverallOutcome({
    required this.scores,
    required this.games,
  });

  MatchOverallOutcome copyWith({
    List<int>? scores,
    List<List<String>>? games,
  }) {
    return MatchOverallOutcome(
      scores: scores ?? this.scores,
      games: games ?? this.games,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'scores': scores,
      'games': games,
    };
  }

  factory MatchOverallOutcome.fromMap(Map<String, dynamic> map) {
    return MatchOverallOutcome(
      scores: List<int>.from((map['scores'] as List<dynamic>)),
      games: List<List<String>>.from(
        (map['games'] as List<dynamic>).map<List<String>>(
          (x) => x,
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory MatchOverallOutcome.fromJson(String source) =>
      MatchOverallOutcome.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'MatchOverallOutcome(scores: $scores, games: $games)';

  @override
  bool operator ==(covariant MatchOverallOutcome other) {
    if (identical(this, other)) return true;

    return listEquals(other.scores, scores) && listEquals(other.games, games);
  }

  @override
  int get hashCode => scores.hashCode ^ games.hashCode;
}
