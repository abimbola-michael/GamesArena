// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:hive_flutter/adapters.dart';

import 'game.dart';
import 'match.dart';

class GameList {
  String game_id;
  String time;
  String? time_end;
  int? lastSeenIndex;
  String? lastSeen;
  Game? game;
  Match? match;
  int? unseen;
  GameList({
    required this.game_id,
    required this.time,
    this.time_end,
    this.lastSeenIndex,
    this.lastSeen,
    this.game,
    this.match,
    this.unseen,
  });

  GameList copyWith({
    String? game_id,
    String? time,
    String? time_end,
    int? lastSeenIndex,
    String? lastSeen,
    Game? game,
    Match? match,
    int? unseen,
  }) {
    return GameList(
      game_id: game_id ?? this.game_id,
      time: time ?? this.time,
      time_end: time_end ?? this.time_end,
      lastSeenIndex: lastSeenIndex ?? this.lastSeenIndex,
      lastSeen: lastSeen ?? this.lastSeen,
      game: game ?? this.game,
      match: match ?? this.match,
      unseen: unseen ?? this.unseen,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'game_id': game_id,
      'time': time,
      'time_end': time_end,
      'lastSeenIndex': lastSeenIndex,
      'lastSeen': lastSeen,
      'game': game?.toMap(),
      'match': match?.toMap(),
      'unseen': unseen,
    };
  }

  factory GameList.fromMap(Map<String, dynamic> map) {
    return GameList(
      game_id: map['game_id'] as String,
      time: map['time'] as String,
      time_end: map['time_end'] != null ? map['time_end'] as String : null,
      lastSeenIndex:
          map['lastSeenIndex'] != null ? map['lastSeenIndex'] as int : null,
      lastSeen: map['lastSeen'] != null ? map['lastSeen'] as String : null,
      game: map['game'] != null
          ? Game.fromMap(map['game'] as Map<String, dynamic>)
          : null,
      match: map['match'] != null
          ? Match.fromMap(map['match'] as Map<String, dynamic>)
          : null,
      unseen: map['unseen'] != null ? map['unseen'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory GameList.fromJson(String source) =>
      GameList.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'GameList(game_id: $game_id, time: $time, time_end: $time_end, lastSeenIndex: $lastSeenIndex, lastSeen: $lastSeen, game: $game, match: $match, unseen: $unseen)';
  }

  @override
  bool operator ==(covariant GameList other) {
    if (identical(this, other)) return true;

    return other.game_id == game_id &&
        other.time == time &&
        other.time_end == time_end &&
        other.lastSeenIndex == lastSeenIndex &&
        other.lastSeen == lastSeen &&
        other.game == game &&
        other.match == match &&
        other.unseen == unseen;
  }

  @override
  int get hashCode {
    return game_id.hashCode ^
        time.hashCode ^
        time_end.hashCode ^
        lastSeenIndex.hashCode ^
        lastSeen.hashCode ^
        game.hashCode ^
        match.hashCode ^
        unseen.hashCode;
  }
}
