// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:gamesarena/features/records/models/match_round.dart';

class MatchRecord {
  int id;
  String game;
  String time_start;
  String? time_end;
  List<String> players;
  Map<String, dynamic> scores;
  Map<String, dynamic> rounds;

  MatchRecord({
    required this.id,
    required this.game,
    required this.time_start,
    this.time_end,
    required this.players,
    required this.scores,
    required this.rounds,
  });

  MatchRecord copyWith({
    int? id,
    String? game,
    String? time_start,
    String? time_end,
    List<String>? players,
    Map<String, dynamic>? scores,
    Map<String, dynamic>? rounds,
  }) {
    return MatchRecord(
      id: id ?? this.id,
      game: game ?? this.game,
      time_start: time_start ?? this.time_start,
      time_end: time_end ?? this.time_end,
      players: players ?? this.players,
      scores: scores ?? this.scores,
      rounds: rounds ?? this.rounds,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'game': game,
      'time_start': time_start,
      'time_end': time_end,
      'players': players,
      'scores': scores,
      'rounds': rounds,
    };
  }

  factory MatchRecord.fromMap(Map<String, dynamic> map) {
    return MatchRecord(
      id: map['id'] as int,
      game: map['game'] as String,
      time_start: map['time_start'] as String,
      time_end: map['time_end'] != null ? map['time_end'] as String : null,
      players: List<String>.from((map['players'] as List<dynamic>)),
      scores: Map<String, dynamic>.from((map['scores'])),
      rounds: Map<String, dynamic>.from((map['rounds'])),
    );
  }

  String toJson() => json.encode(toMap());

  factory MatchRecord.fromJson(String source) =>
      MatchRecord.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MatchRecord(id: $id, game: $game, time_start: $time_start, time_end: $time_end, players: $players, scores: $scores, rounds: $rounds)';
  }

  @override
  bool operator ==(covariant MatchRecord other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.game == game &&
        other.time_start == time_start &&
        other.time_end == time_end &&
        listEquals(other.players, players) &&
        mapEquals(other.scores, scores) &&
        mapEquals(other.rounds, rounds);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        game.hashCode ^
        time_start.hashCode ^
        time_end.hashCode ^
        players.hashCode ^
        scores.hashCode ^
        rounds.hashCode;
  }

  List<MatchRound> getMatchRounds() {
    List<MatchRound> matchRounds = [];
    for (int i = 0; i < rounds.length; i++) {
      final round = rounds["$i"];
      final matchRound = MatchRound.fromMap(round);
      matchRounds.add(matchRound);
    }
    return matchRounds;
  }
}
