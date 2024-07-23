// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class MatchRecord {
  int id;
  String game;
  String time_start;
  String time_end;
  int? duration;
  int? player1Score;
  int? player2Score;
  int? player3Score;
  int? player4Score;
  MatchRecord({
    required this.id,
    required this.game,
    required this.time_start,
    required this.time_end,
    this.duration,
    this.player1Score,
    this.player2Score,
    this.player3Score,
    this.player4Score,
  });

  MatchRecord copyWith({
    int? id,
    String? game,
    String? time_start,
    String? time_end,
    int? duration,
    int? player1Score,
    int? player2Score,
    int? player3Score,
    int? player4Score,
  }) {
    return MatchRecord(
      id: id ?? this.id,
      game: game ?? this.game,
      time_start: time_start ?? this.time_start,
      time_end: time_end ?? this.time_end,
      duration: duration ?? this.duration,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      player3Score: player3Score ?? this.player3Score,
      player4Score: player4Score ?? this.player4Score,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'game': game,
      'time_start': time_start,
      'time_end': time_end,
      'duration': duration,
      'player1Score': player1Score,
      'player2Score': player2Score,
      'player3Score': player3Score,
      'player4Score': player4Score,
    };
  }

  factory MatchRecord.fromMap(Map<String, dynamic> map) {
    return MatchRecord(
      id: (map["id"] ?? 0) as int,
      game: (map["game"] ?? '') as String,
      time_start: (map["time_start"] ?? '') as String,
      time_end: (map["time_end"] ?? '') as String,
      duration: map['duration'] != null ? map["duration"] ?? 0 : null,
      player1Score:
          map['player1Score'] != null ? map["player1Score"] ?? 0 : null,
      player2Score:
          map['player2Score'] != null ? map["player2Score"] ?? 0 : null,
      player3Score:
          map['player3Score'] != null ? map["player3Score"] ?? 0 : null,
      player4Score:
          map['player4Score'] != null ? map["player4Score"] ?? 0 : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory MatchRecord.fromJson(String source) =>
      MatchRecord.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MatchRecord(id: $id, game: $game, time_start: $time_start, time_end: $time_end, duration: $duration, player1Score: $player1Score, player2Score: $player2Score, player3Score: $player3Score, player4Score: $player4Score)';
  }

  @override
  bool operator ==(covariant MatchRecord other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.game == game &&
        other.time_start == time_start &&
        other.time_end == time_end &&
        other.duration == duration &&
        other.player1Score == player1Score &&
        other.player2Score == player2Score &&
        other.player3Score == player3Score &&
        other.player4Score == player4Score;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        game.hashCode ^
        time_start.hashCode ^
        time_end.hashCode ^
        duration.hashCode ^
        player1Score.hashCode ^
        player2Score.hashCode ^
        player3Score.hashCode ^
        player4Score.hashCode;
  }
}
