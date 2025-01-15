// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

class MatchRound {
  int id;
  String game;
  String time_start;
  String? time_end;
  List<String> players;
  List<int>? closed_players;
  List<int>? winners;
  Map<String, dynamic> scores;
  int detailsLength;
  double duration;
  MatchRound({
    required this.id,
    required this.game,
    required this.time_start,
    this.time_end,
    required this.players,
    this.closed_players,
    this.winners,
    required this.scores,
    required this.detailsLength,
    required this.duration,
  });

  MatchRound copyWith({
    int? id,
    String? game,
    String? time_start,
    String? time_end,
    List<String>? players,
    List<int>? closed_players,
    List<int>? winners,
    Map<String, dynamic>? scores,
    int? detailsLength,
    double? duration,
  }) {
    return MatchRound(
      id: id ?? this.id,
      game: game ?? this.game,
      time_start: time_start ?? this.time_start,
      time_end: time_end ?? this.time_end,
      players: players ?? this.players,
      closed_players: closed_players ?? this.closed_players,
      winners: winners ?? this.winners,
      scores: scores ?? this.scores,
      detailsLength: detailsLength ?? this.detailsLength,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'game': game,
      'time_start': time_start,
      'time_end': time_end,
      'players': players,
      'closed_players': closed_players,
      'winners': winners,
      'scores': scores,
      'detailsLength': detailsLength,
      'duration': duration,
    };
  }

  factory MatchRound.fromMap(Map<String, dynamic> map) {
    return MatchRound(
      id: map['id'] as int,
      game: map['game'] as String,
      time_start: map['time_start'] as String,
      time_end: map['time_end'] != null ? map['time_end'] as String : null,
      players: List<String>.from((map['players'] as List<dynamic>)),
      closed_players: map['closed_players'] != null
          ? List<int>.from((map['closed_players'] as List<dynamic>))
          : null,
      winners: map['winners'] != null
          ? List<int>.from((map['winners'] as List<dynamic>))
          : null,
      scores:
          Map<String, dynamic>.from((map['scores'] as Map<String, dynamic>)),
      detailsLength: map['detailsLength'] as int,
      duration: map['duration'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory MatchRound.fromJson(String source) =>
      MatchRound.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MatchRound(id: $id, game: $game, time_start: $time_start, time_end: $time_end, players: $players, closed_players: $closed_players, winners: $winners, scores: $scores, detailsLength: $detailsLength, duration: $duration)';
  }

  @override
  bool operator ==(covariant MatchRound other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.game == game &&
        other.time_start == time_start &&
        other.time_end == time_end &&
        listEquals(other.players, players) &&
        listEquals(other.closed_players, closed_players) &&
        listEquals(other.winners, winners) &&
        mapEquals(other.scores, scores) &&
        other.detailsLength == detailsLength &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        game.hashCode ^
        time_start.hashCode ^
        time_end.hashCode ^
        players.hashCode ^
        closed_players.hashCode ^
        winners.hashCode ^
        scores.hashCode ^
        detailsLength.hashCode ^
        duration.hashCode;
  }
}
