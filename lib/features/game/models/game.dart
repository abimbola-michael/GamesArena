// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../records/models/game_stat.dart';
import '../../user/models/user.dart';
import '../../user/models/user_game.dart';
import 'match.dart';

class Game {
  String game_id;
  String time;
  String? time_deleted;
  String? creatorId;
  String? groupName;
  String? profilePhoto;
  String? firstMatchTime;
  GameStat? gameStat;
  List<UserGame>? user_games;
  List<String>? players;
  List<User>? users;

  Game({
    required this.game_id,
    required this.time,
    this.time_deleted,
    this.creatorId,
    this.groupName,
    this.profilePhoto,
    this.firstMatchTime,
    this.user_games,
    this.players,
  });

  Game copyWith({
    String? game_id,
    String? time,
    String? time_deleted,
    String? creatorId,
    String? groupName,
    String? profilePhoto,
    String? firstMatchTime,
    List<UserGame>? user_games,
    List<String>? players,
  }) {
    return Game(
      game_id: game_id ?? this.game_id,
      time: time ?? this.time,
      time_deleted: time_deleted ?? this.time_deleted,
      creatorId: creatorId ?? this.creatorId,
      groupName: groupName ?? this.groupName,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      firstMatchTime: firstMatchTime ?? this.firstMatchTime,
      user_games: user_games ?? this.user_games,
      players: players ?? this.players,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'game_id': game_id,
      'time': time,
      'time_deleted': time_deleted,
      'creatorId': creatorId,
      'groupName': groupName,
      'profilePhoto': profilePhoto,
      'firstMatchTime': firstMatchTime,
      'user_games': user_games?.map((x) => x?.toMap()).toList(),
      'players': players,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      game_id: map['game_id'] as String,
      time: map['time'] as String,
      time_deleted:
          map['time_deleted'] != null ? map['time_deleted'] as String : null,
      creatorId: map['creatorId'] != null ? map['creatorId'] as String : null,
      groupName: map['groupName'] != null ? map['groupName'] as String : null,
      profilePhoto:
          map['profilePhoto'] != null ? map['profilePhoto'] as String : null,
      firstMatchTime: map['firstMatchTime'] != null
          ? map['firstMatchTime'] as String
          : null,
      user_games: map['user_games'] != null
          ? List<UserGame>.from(
              (map['user_games'] as List<dynamic>).map<UserGame?>(
                (x) => UserGame.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      players: map['players'] != null
          ? List<String>.from((map['players'] as List<dynamic>))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Game.fromJson(String source) =>
      Game.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Game(game_id: $game_id, time: $time, time_deleted: $time_deleted, creatorId: $creatorId, groupName: $groupName, profilePhoto: $profilePhoto, firstMatchTime: $firstMatchTime, user_games: $user_games, players: $players)';
  }

  @override
  bool operator ==(covariant Game other) {
    if (identical(this, other)) return true;

    return other.game_id == game_id &&
        other.time == time &&
        other.time_deleted == time_deleted &&
        other.creatorId == creatorId &&
        other.groupName == groupName &&
        other.profilePhoto == profilePhoto &&
        other.firstMatchTime == firstMatchTime &&
        listEquals(other.user_games, user_games) &&
        listEquals(other.players, players);
  }

  @override
  int get hashCode {
    return game_id.hashCode ^
        time.hashCode ^
        time_deleted.hashCode ^
        creatorId.hashCode ^
        groupName.hashCode ^
        profilePhoto.hashCode ^
        firstMatchTime.hashCode ^
        user_games.hashCode ^
        players.hashCode;
  }
}
