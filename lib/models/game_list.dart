// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class GameList {
  String game_id;
  String time;
  GameList({
    required this.game_id,
    required this.time,
  });

  GameList copyWith({
    String? game_id,
    String? time,
  }) {
    return GameList(
      game_id: game_id ?? this.game_id,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'game_id': game_id,
      'time': time,
    };
  }

  factory GameList.fromMap(Map<String, dynamic> map) {
    return GameList(
      game_id: (map["game_id"] ?? '') as String,
      time: (map["time"] ?? '') as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory GameList.fromJson(String source) =>
      GameList.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'GameList(game_id: $game_id, time: $time)';

  @override
  bool operator ==(covariant GameList other) {
    if (identical(this, other)) return true;

    return other.game_id == game_id && other.time == time;
  }

  @override
  int get hashCode => game_id.hashCode ^ time.hashCode;
}
