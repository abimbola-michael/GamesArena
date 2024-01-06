// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Match {
  String? match_id;
  String? creator_id;
  String? time_created;
  String? time_start;
  String? time_end;
  String? player1;
  String? player2;
  String? player3;
  String? player4;
  Match({
    required this.match_id,
    this.creator_id,
    this.time_created,
    this.time_start,
    this.time_end,
    this.player1,
    this.player2,
    this.player3,
    this.player4,
  });

  Match copyWith({
    String? match_id,
    String? creator_id,
    String? time_created,
    String? time_start,
    String? time_end,
    String? player1,
    String? player2,
    String? player3,
    String? player4,
  }) {
    return Match(
      match_id: match_id ?? this.match_id,
      creator_id: creator_id ?? this.creator_id,
      time_created: time_created ?? this.time_created,
      time_start: time_start ?? this.time_start,
      time_end: time_end ?? this.time_end,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      player3: player3 ?? this.player3,
      player4: player4 ?? this.player4,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'match_id': match_id,
      'creator_id': creator_id,
      'time_created': time_created,
      'time_start': time_start,
      'time_end': time_end,
      'player1': player1,
      'player2': player2,
      'player3': player3,
      'player4': player4,
    };
  }

  factory Match.fromMap(Map<String, dynamic> map) {
    return Match(
      match_id:
          map['match_id'] != null ? map["match_id"] ?? '' : null,
      creator_id:
          map['creator_id'] != null ? map["creator_id"] ?? '' : null,
      time_created: map['time_created'] != null
          ? map["time_created"] ?? ''
          : null,
      time_start:
          map['time_start'] != null ? map["time_start"] ?? '' : null,
      time_end:
          map['time_end'] != null ? map["time_end"] ?? '' : null,
      player1: map['player1'] != null ? map["player1"] ?? '' : null,
      player2: map['player2'] != null ? map["player2"] ?? '' : null,
      player3: map['player3'] != null ? map["player3"] ?? '' : null,
      player4: map['player4'] != null ? map["player4"] ?? '' : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Match.fromJson(String source) =>
      Match.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Match(match_id: $match_id, creator_id: $creator_id, time_created: $time_created, time_start: $time_start, time_end: $time_end, player1: $player1, player2: $player2, player3: $player3, player4: $player4)';
  }

  @override
  bool operator ==(covariant Match other) {
    if (identical(this, other)) return true;

    return other.match_id == match_id &&
        other.creator_id == creator_id &&
        other.time_created == time_created &&
        other.time_start == time_start &&
        other.time_end == time_end &&
        other.player1 == player1 &&
        other.player2 == player2 &&
        other.player3 == player3 &&
        other.player4 == player4;
  }

  @override
  int get hashCode {
    return match_id.hashCode ^
        creator_id.hashCode ^
        time_created.hashCode ^
        time_start.hashCode ^
        time_end.hashCode ^
        player1.hashCode ^
        player2.hashCode ^
        player3.hashCode ^
        player4.hashCode;
  }
}
