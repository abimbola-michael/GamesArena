// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import '../../../shared/models/models.dart';

class PlayersFormation {
  String? player1;
  String? player2;
  String? player3;
  String? player4;
  User? user1;
  User? user2;
  User? user3;
  User? user4;
  int? player1Score;
  int? player2Score;
  int? player3Score;
  int? player4Score;
  PlayersFormation({
    this.player1,
    this.player2,
    this.player3,
    this.player4,
    this.user1,
    this.user2,
    this.user3,
    this.user4,
    this.player1Score,
    this.player2Score,
    this.player3Score,
    this.player4Score,
  });

  PlayersFormation copyWith({
    String? player1,
    String? player2,
    String? player3,
    String? player4,
    User? user1,
    User? user2,
    User? user3,
    User? user4,
    int? player1Score,
    int? player2Score,
    int? player3Score,
    int? player4Score,
  }) {
    return PlayersFormation(
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      player3: player3 ?? this.player3,
      player4: player4 ?? this.player4,
      user1: user1 ?? this.user1,
      user2: user2 ?? this.user2,
      user3: user3 ?? this.user3,
      user4: user4 ?? this.user4,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      player3Score: player3Score ?? this.player3Score,
      player4Score: player4Score ?? this.player4Score,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'player1': player1,
      'player2': player2,
      'player3': player3,
      'player4': player4,
      'user1': user1?.toMap(),
      'user2': user2?.toMap(),
      'user3': user3?.toMap(),
      'user4': user4?.toMap(),
      'player1Score': player1Score,
      'player2Score': player2Score,
      'player3Score': player3Score,
      'player4Score': player4Score,
    };
  }

  factory PlayersFormation.fromMap(Map<String, dynamic> map) {
    return PlayersFormation(
      player1: map['player1'] != null ? map["player1"] ?? '' : null,
      player2: map['player2'] != null ? map["player2"] ?? '' : null,
      player3: map['player3'] != null ? map["player3"] ?? '' : null,
      player4: map['player4'] != null ? map["player4"] ?? '' : null,
      user1: map['user1'] != null
          ? User.fromMap((map["user1"] ?? Map<String, dynamic>.from({}))
              as Map<String, dynamic>)
          : null,
      user2: map['user2'] != null
          ? User.fromMap((map["user2"] ?? Map<String, dynamic>.from({}))
              as Map<String, dynamic>)
          : null,
      user3: map['user3'] != null
          ? User.fromMap((map["user3"] ?? Map<String, dynamic>.from({}))
              as Map<String, dynamic>)
          : null,
      user4: map['user4'] != null
          ? User.fromMap((map["user4"] ?? Map<String, dynamic>.from({}))
              as Map<String, dynamic>)
          : null,
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

  factory PlayersFormation.fromJson(String source) =>
      PlayersFormation.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PlayersFormation(player1: $player1, player2: $player2, player3: $player3, player4: $player4, user1: $user1, user2: $user2, user3: $user3, user4: $user4, player1Score: $player1Score, player2Score: $player2Score, player3Score: $player3Score, player4Score: $player4Score)';
  }

  @override
  bool operator ==(covariant PlayersFormation other) {
    if (identical(this, other)) return true;

    return other.player1 == player1 &&
        other.player2 == player2 &&
        other.player3 == player3 &&
        other.player4 == player4 &&
        other.user1 == user1 &&
        other.user2 == user2 &&
        other.user3 == user3 &&
        other.user4 == user4 &&
        other.player1Score == player1Score &&
        other.player2Score == player2Score &&
        other.player3Score == player3Score &&
        other.player4Score == player4Score;
  }

  @override
  int get hashCode {
    return player1.hashCode ^
        player2.hashCode ^
        player3.hashCode ^
        player4.hashCode ^
        user1.hashCode ^
        user2.hashCode ^
        user3.hashCode ^
        user4.hashCode ^
        player1Score.hashCode ^
        player2Score.hashCode ^
        player3Score.hashCode ^
        player4Score.hashCode;
  }
}
