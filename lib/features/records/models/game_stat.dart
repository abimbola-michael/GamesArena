// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class GameStat {
  int players;
  int allMatches;
  int playedMatches;
  int wins;
  int draws;
  int losses;
  GameStat({
    required this.players,
    required this.allMatches,
    required this.playedMatches,
    required this.wins,
    required this.draws,
    required this.losses,
  });

  GameStat copyWith({
    int? players,
    int? allMatches,
    int? playedMatches,
    int? wins,
    int? draws,
    int? losses,
  }) {
    return GameStat(
      players: players ?? this.players,
      allMatches: allMatches ?? this.allMatches,
      playedMatches: playedMatches ?? this.playedMatches,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'players': players,
      'allMatches': allMatches,
      'playedMatches': playedMatches,
      'wins': wins,
      'draws': draws,
      'losses': losses,
    };
  }

  factory GameStat.fromMap(Map<String, dynamic> map) {
    return GameStat(
      players: map['players'] as int,
      allMatches: map['allMatches'] as int,
      playedMatches: map['playedMatches'] as int,
      wins: map['wins'] as int,
      draws: map['draws'] as int,
      losses: map['losses'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory GameStat.fromJson(String source) =>
      GameStat.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'GameStat(players: $players, allMatches: $allMatches, playedMatches: $playedMatches, wins: $wins, draws: $draws, losses: $losses)';
  }

  @override
  bool operator ==(covariant GameStat other) {
    if (identical(this, other)) return true;

    return other.players == players &&
        other.allMatches == allMatches &&
        other.playedMatches == playedMatches &&
        other.wins == wins &&
        other.draws == draws &&
        other.losses == losses;
  }

  @override
  int get hashCode {
    return players.hashCode ^
        allMatches.hashCode ^
        playedMatches.hashCode ^
        wins.hashCode ^
        draws.hashCode ^
        losses.hashCode;
  }
}
