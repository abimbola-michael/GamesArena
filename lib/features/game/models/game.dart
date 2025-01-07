// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../records/models/game_stat.dart';
import '../../user/models/user.dart';
import '../../user/models/user_game.dart';
import 'match.dart';

class Game {
  String game_id;
  String time_created;
  String? time_modified;
  String? time_deleted;
  String? user_id;
  String? creatorId;
  String? groupName;
  String? profilePhoto;
  GameStat? gameStat;
  List<String>? games;
  List<String>? players;
  List<User>? users;
  // List<UserGame>? user_games;

  Game({
    required this.game_id,
    required this.time_created,
    this.time_modified,
    this.time_deleted,
    this.user_id,
    this.creatorId,
    this.groupName,
    this.profilePhoto,
    this.games,
    this.players,
    this.users,
  });

  Game copyWith({
    String? game_id,
    String? time_created,
    String? time_modified,
    String? time_deleted,
    String? user_id,
    String? creatorId,
    String? groupName,
    String? profilePhoto,
    List<String>? games,
    List<String>? players,
    List<User>? users,
  }) {
    return Game(
      game_id: game_id ?? this.game_id,
      time_created: time_created ?? this.time_created,
      time_modified: time_modified ?? this.time_modified,
      time_deleted: time_deleted ?? this.time_deleted,
      user_id: user_id ?? this.user_id,
      creatorId: creatorId ?? this.creatorId,
      groupName: groupName ?? this.groupName,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      games: games ?? this.games,
      players: players ?? this.players,
      users: users ?? this.users,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'game_id': game_id,
      'time_created': time_created,
      'time_modified': time_modified,
      'time_deleted': time_deleted,
      'user_id': user_id,
      'creatorId': creatorId,
      'groupName': groupName,
      'profilePhoto': profilePhoto,
      'games': games,
      'players': players,
      'users': users?.map((x) => x?.toMap()).toList(),
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      game_id: map['game_id'] as String,
      time_created: map['time_created'] as String,
      time_modified:
          map['time_modified'] != null ? map['time_modified'] as String : null,
      time_deleted:
          map['time_deleted'] != null ? map['time_deleted'] as String : null,
      user_id: map['user_id'] != null ? map['user_id'] as String : null,
      creatorId: map['creatorId'] != null ? map['creatorId'] as String : null,
      groupName: map['groupName'] != null ? map['groupName'] as String : null,
      profilePhoto:
          map['profilePhoto'] != null ? map['profilePhoto'] as String : null,
      games: map['games'] != null
          ? List<String>.from((map['games'] as List<dynamic>))
          : null,
      players: map['players'] != null
          ? List<String>.from((map['players'] as List<dynamic>))
          : null,
      users: map['users'] != null
          ? List<User>.from(
              (map['users'] as List<dynamic>).map<User?>(
                (x) => User.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Game.fromJson(String source) =>
      Game.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Game(game_id: $game_id, time_created: $time_created, time_modified: $time_modified, time_deleted: $time_deleted, user_id: $user_id, creatorId: $creatorId, groupName: $groupName, profilePhoto: $profilePhoto, games: $games, players: $players, users: $users)';
  }

  @override
  bool operator ==(covariant Game other) {
    if (identical(this, other)) return true;

    return other.game_id == game_id &&
        other.time_created == time_created &&
        other.time_modified == time_modified &&
        other.time_deleted == time_deleted &&
        other.user_id == user_id &&
        other.creatorId == creatorId &&
        other.groupName == groupName &&
        other.profilePhoto == profilePhoto &&
        listEquals(other.games, games) &&
        listEquals(other.players, players) &&
        listEquals(other.users, users);
  }

  @override
  int get hashCode {
    return game_id.hashCode ^
        time_created.hashCode ^
        time_modified.hashCode ^
        time_deleted.hashCode ^
        user_id.hashCode ^
        creatorId.hashCode ^
        groupName.hashCode ^
        profilePhoto.hashCode ^
        games.hashCode ^
        players.hashCode ^
        users.hashCode;
  }
}
