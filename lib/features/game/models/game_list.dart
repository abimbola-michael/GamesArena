// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:hive_flutter/adapters.dart';

import 'game.dart';
import 'match.dart';

class GameList {
  String game_id;
  String time_created;
  String? time_start;
  String? time_end;
  String? time_deleted;
  String? time_modified;
  String? time_seen;
  String? user_id;
  Game? game;
  Match? match;
  int? unseen;
  GameList({
    required this.game_id,
    required this.time_created,
    this.time_start,
    this.time_end,
    this.time_deleted,
    this.time_modified,
    this.time_seen,
    this.user_id,
    this.game,
    this.match,
    this.unseen,
  });

  GameList copyWith({
    String? game_id,
    String? time_created,
    String? time_start,
    String? time_end,
    String? time_deleted,
    String? time_modified,
    String? time_seen,
    String? user_id,
    Game? game,
    Match? match,
    int? unseen,
  }) {
    return GameList(
      game_id: game_id ?? this.game_id,
      time_created: time_created ?? this.time_created,
      time_start: time_start ?? this.time_start,
      time_end: time_end ?? this.time_end,
      time_deleted: time_deleted ?? this.time_deleted,
      time_modified: time_modified ?? this.time_modified,
      time_seen: time_seen ?? this.time_seen,
      user_id: user_id ?? this.user_id,
      game: game ?? this.game,
      match: match ?? this.match,
      unseen: unseen ?? this.unseen,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'game_id': game_id,
      'time_created': time_created,
      'time_start': time_start,
      'time_end': time_end,
      'time_deleted': time_deleted,
      'time_modified': time_modified,
      'time_seen': time_seen,
      'user_id': user_id,
      'game': game?.toMap(),
      'match': match?.toMap(),
      'unseen': unseen,
    };
  }

  factory GameList.fromMap(Map<String, dynamic> map) {
    return GameList(
      game_id: map['game_id'] as String,
      time_created: map['time_created'] as String,
      time_start:
          map['time_start'] != null ? map['time_start'] as String : null,
      time_end: map['time_end'] != null ? map['time_end'] as String : null,
      time_deleted:
          map['time_deleted'] != null ? map['time_deleted'] as String : null,
      time_modified:
          map['time_modified'] != null ? map['time_modified'] as String : null,
      time_seen: map['time_seen'] != null ? map['time_seen'] as String : null,
      user_id: map['user_id'] != null ? map['user_id'] as String : null,
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
    return 'GameList(game_id: $game_id, time_created: $time_created, time_start: $time_start, time_end: $time_end, time_deleted: $time_deleted, time_modified: $time_modified, time_seen: $time_seen, user_id: $user_id, game: $game, match: $match, unseen: $unseen)';
  }

  @override
  bool operator ==(covariant GameList other) {
    if (identical(this, other)) return true;

    return other.game_id == game_id &&
            other.time_created == time_created &&
            other.time_start == time_start &&
            other.time_end == time_end &&
            other.time_deleted == time_deleted &&
            other.time_modified == time_modified &&
            other.time_seen == time_seen &&
            other.user_id == user_id
        // &&
        // other.game == game &&
        // other.match == match &&
        // other.unseen == unseen
        ;
  }

  @override
  int get hashCode {
    return game_id.hashCode ^
        time_created.hashCode ^
        time_start.hashCode ^
        time_end.hashCode ^
        time_deleted.hashCode ^
        time_modified.hashCode ^
        time_seen.hashCode ^
        user_id.hashCode ^
        game.hashCode ^
        match.hashCode ^
        unseen.hashCode;
  }
}
