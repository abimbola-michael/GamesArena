// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class GameRequest {
  String game;
  String game_id;
  String match_id;
  String creator_id;
  String time;
  GameRequest({
    required this.game,
    required this.game_id,
    required this.match_id,
    required this.creator_id,
    required this.time,
  });

  GameRequest copyWith({
    String? game,
    String? game_id,
    String? match_id,
    String? creator_id,
    String? time,
  }) {
    return GameRequest(
      game: game ?? this.game,
      game_id: game_id ?? this.game_id,
      match_id: match_id ?? this.match_id,
      creator_id: creator_id ?? this.creator_id,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'game': game,
      'game_id': game_id,
      'match_id': match_id,
      'creator_id': creator_id,
      'time': time,
    };
  }

  factory GameRequest.fromMap(Map<String, dynamic> map) {
    return GameRequest(
      game: map['game'] as String,
      game_id: map['game_id'] as String,
      match_id: map['match_id'] as String,
      creator_id: map['creator_id'] as String,
      time: map['time'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory GameRequest.fromJson(String source) =>
      GameRequest.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'GameRequest(game: $game, game_id: $game_id, match_id: $match_id, creator_id: $creator_id, time: $time)';
  }

  @override
  bool operator ==(covariant GameRequest other) {
    if (identical(this, other)) return true;

    return other.game == game &&
        other.game_id == game_id &&
        other.match_id == match_id &&
        other.creator_id == creator_id &&
        other.time == time;
  }

  @override
  int get hashCode {
    return game.hashCode ^
        game_id.hashCode ^
        match_id.hashCode ^
        creator_id.hashCode ^
        time.hashCode;
  }
}
