// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Game {
  String game_id = "";
  String players = "";
  String time = "";
  Game({
    required this.game_id,
    required this.players,
    required this.time,
  });

  Game copyWith({
    String? game_id,
    String? players,
    String? time,
  }) {
    return Game(
      game_id: game_id ?? this.game_id,
      players: players ?? this.players,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'game_id': game_id,
      'players': players,
      'time': time,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      game_id: (map["game_id"] ?? '') as String,
      players: (map["players"] ?? '') as String,
      time: (map["time"] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Game.fromJson(String source) =>
      Game.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Game(game_id: $game_id, players: $players, time: $time)';

  @override
  bool operator ==(covariant Game other) {
    if (identical(this, other)) return true;

    return other.game_id == game_id &&
        other.players == players &&
        other.time == time;
  }

  @override
  int get hashCode => game_id.hashCode ^ players.hashCode ^ time.hashCode;
}
