// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'package:gamesarena/features/records/models/match_record.dart';

import '../../user/models/user.dart';

class Match {
  String? match_id;
  String? game_id;
  int? index;
  String? creator_id;
  String? time_created;
  String? time_modified;
  String? time_deleted;
  String? time_start;
  String? time_end;
  String? game;
  List<String>? players;
  String? outcome;
  List<String>? winners;
  List<String>? others;
  List<int>? scores;
  int? recordsCount;

  Map<String, dynamic>? records;
  List<User>? users;
  Match({
    required this.match_id,
    this.game_id,
    this.index,
    this.creator_id,
    this.time_created,
    this.time_modified,
    this.time_deleted,
    this.time_start,
    this.time_end,
    this.game,
    this.players,
    this.outcome,
    this.winners,
    this.others,
    this.scores,
    this.recordsCount,
    this.records,
  });

  Match copyWith({
    String? match_id,
    String? game_id,
    int? index,
    String? creator_id,
    String? time_created,
    String? time_modified,
    String? time_deleted,
    String? time_start,
    String? time_end,
    String? game,
    List<String>? players,
    String? outcome,
    List<String>? winners,
    List<String>? others,
    List<int>? scores,
    int? recordsCount,
    Map<String, dynamic>? records,
  }) {
    return Match(
      match_id: match_id ?? this.match_id,
      game_id: game_id ?? this.game_id,
      index: index ?? this.index,
      creator_id: creator_id ?? this.creator_id,
      time_created: time_created ?? this.time_created,
      time_modified: time_modified ?? this.time_modified,
      time_deleted: time_deleted ?? this.time_deleted,
      time_start: time_start ?? this.time_start,
      time_end: time_end ?? this.time_end,
      game: game ?? this.game,
      players: players ?? this.players,
      outcome: outcome ?? this.outcome,
      winners: winners ?? this.winners,
      others: others ?? this.others,
      scores: scores ?? this.scores,
      recordsCount: recordsCount ?? this.recordsCount,
      records: records ?? this.records,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'match_id': match_id,
      'game_id': game_id,
      'index': index,
      'creator_id': creator_id,
      'time_created': time_created,
      'time_modified': time_modified,
      'time_deleted': time_deleted,
      'time_start': time_start,
      'time_end': time_end,
      'game': game,
      'players': players,
      'outcome': outcome,
      'winners': winners,
      'others': others,
      'scores': scores,
      'recordsCount': recordsCount,
      'records': records,
    };
  }

  factory Match.fromMap(Map<String, dynamic> map) {
    return Match(
      match_id: map['match_id'] != null ? map['match_id'] as String : null,
      game_id: map['game_id'] != null ? map['game_id'] as String : null,
      index: map['index'] != null ? map['index'] as int : null,
      creator_id:
          map['creator_id'] != null ? map['creator_id'] as String : null,
      time_created:
          map['time_created'] != null ? map['time_created'] as String : null,
      time_modified:
          map['time_modified'] != null ? map['time_modified'] as String : null,
      time_deleted:
          map['time_deleted'] != null ? map['time_deleted'] as String : null,
      time_start:
          map['time_start'] != null ? map['time_start'] as String : null,
      time_end: map['time_end'] != null ? map['time_end'] as String : null,
      game: map['game'] != null ? map['game'] as String : null,
      players: map['players'] != null
          ? List<String>.from((map['players'] as List<dynamic>))
          : null,
      outcome: map['outcome'] != null ? map['outcome'] as String : null,
      winners: map['winners'] != null
          ? List<String>.from((map['winners'] as List<dynamic>))
          : null,
      others: map['others'] != null
          ? List<String>.from((map['others'] as List<dynamic>))
          : null,
      scores: map['scores'] != null
          ? List<int>.from((map['scores'] as List<dynamic>))
          : null,
      recordsCount:
          map['recordsCount'] != null ? map['recordsCount'] as int : null,
      records: map['records'] != null
          ? Map<String, dynamic>.from((map['records'] as Map<String, dynamic>))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Match.fromJson(String source) =>
      Match.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Match(match_id: $match_id, game_id: $game_id, index: $index, creator_id: $creator_id, time_created: $time_created, time_modified: $time_modified, time_deleted: $time_deleted, time_start: $time_start, time_end: $time_end, game: $game, players: $players, outcome: $outcome, winners: $winners, others: $others, scores: $scores, recordsCount: $recordsCount, records: $records)';
  }

  @override
  bool operator ==(covariant Match other) {
    if (identical(this, other)) return true;

    return other.match_id == match_id &&
        other.game_id == game_id &&
        other.index == index &&
        other.creator_id == creator_id &&
        other.time_created == time_created &&
        other.time_modified == time_modified &&
        other.time_deleted == time_deleted &&
        other.time_start == time_start &&
        other.time_end == time_end &&
        other.game == game &&
        listEquals(other.players, players) &&
        other.outcome == outcome &&
        listEquals(other.winners, winners) &&
        listEquals(other.others, others) &&
        listEquals(other.scores, scores) &&
        other.recordsCount == recordsCount &&
        mapEquals(other.records, records);
  }

  @override
  int get hashCode {
    return match_id.hashCode ^
        game_id.hashCode ^
        index.hashCode ^
        creator_id.hashCode ^
        time_created.hashCode ^
        time_modified.hashCode ^
        time_deleted.hashCode ^
        time_start.hashCode ^
        time_end.hashCode ^
        game.hashCode ^
        players.hashCode ^
        outcome.hashCode ^
        winners.hashCode ^
        others.hashCode ^
        scores.hashCode ^
        recordsCount.hashCode ^
        records.hashCode;
  }
}
