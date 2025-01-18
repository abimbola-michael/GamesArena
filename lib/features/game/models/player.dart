// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:gamesarena/features/user/models/user.dart';

import 'game_list.dart';

class Player {
  String id;
  String time;
  String? time_modified;
  String? role;
  String? action;
  int? order;
  String? game;
  String? gameId;
  String? matchId;
  String? callMode;
  bool? isAudioOn;
  bool? isFrontCamera;
  User? user;
  GameList? gameList;
  Player({
    required this.id,
    required this.time,
    this.time_modified,
    this.role,
    this.action,
    this.order,
    this.game,
    this.gameId,
    this.matchId,
    this.callMode,
    this.isAudioOn,
    this.isFrontCamera,
    this.user,
    this.gameList,
  });

  Player copyWith({
    String? id,
    String? time,
    String? time_modified,
    String? role,
    String? action,
    int? order,
    String? game,
    String? gameId,
    String? matchId,
    String? callMode,
    bool? isAudioOn,
    bool? isFrontCamera,
    User? user,
    GameList? gameList,
  }) {
    return Player(
      id: id ?? this.id,
      time: time ?? this.time,
      time_modified: time_modified ?? this.time_modified,
      role: role ?? this.role,
      action: action ?? this.action,
      order: order ?? this.order,
      game: game ?? this.game,
      gameId: gameId ?? this.gameId,
      matchId: matchId ?? this.matchId,
      callMode: callMode ?? this.callMode,
      isAudioOn: isAudioOn ?? this.isAudioOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      user: user ?? this.user,
      gameList: gameList ?? this.gameList,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'time': time,
      'time_modified': time_modified,
      'role': role,
      'action': action,
      'order': order,
      'game': game,
      'gameId': gameId,
      'matchId': matchId,
      'callMode': callMode,
      'isAudioOn': isAudioOn,
      'isFrontCamera': isFrontCamera,
      'user': user?.toMap(),
      'gameList': gameList?.toMap(),
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      time: map['time'] as String,
      time_modified:
          map['time_modified'] != null ? map['time_modified'] as String : null,
      role: map['role'] != null ? map['role'] as String : null,
      action: map['action'] != null ? map['action'] as String : null,
      order: map['order'] != null ? map['order'] as int : null,
      game: map['game'] != null ? map['game'] as String : null,
      gameId: map['gameId'] != null ? map['gameId'] as String : null,
      matchId: map['matchId'] != null ? map['matchId'] as String : null,
      callMode: map['callMode'] != null ? map['callMode'] as String : null,
      isAudioOn: map['isAudioOn'] != null ? map['isAudioOn'] as bool : null,
      isFrontCamera:
          map['isFrontCamera'] != null ? map['isFrontCamera'] as bool : null,
      user: map['user'] != null
          ? User.fromMap(map['user'] as Map<String, dynamic>)
          : null,
      gameList: map['gameList'] != null
          ? GameList.fromMap(map['gameList'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Player.fromJson(String source) =>
      Player.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Player(id: $id, time: $time, time_modified: $time_modified, role: $role, action: $action, order: $order, game: $game, gameId: $gameId, matchId: $matchId, callMode: $callMode, isAudioOn: $isAudioOn, isFrontCamera: $isFrontCamera, user: $user, gameList: $gameList)';
  }

  @override
  bool operator ==(covariant Player other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.time == time &&
        other.time_modified == time_modified &&
        other.role == role &&
        other.action == action &&
        other.order == order &&
        other.game == game &&
        other.gameId == gameId &&
        other.matchId == matchId &&
        other.callMode == callMode &&
        other.isAudioOn == isAudioOn &&
        other.isFrontCamera == isFrontCamera &&
        other.user == user &&
        other.gameList == gameList;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        time.hashCode ^
        time_modified.hashCode ^
        role.hashCode ^
        action.hashCode ^
        order.hashCode ^
        game.hashCode ^
        gameId.hashCode ^
        matchId.hashCode ^
        callMode.hashCode ^
        isAudioOn.hashCode ^
        isFrontCamera.hashCode ^
        user.hashCode ^
        gameList.hashCode;
  }
}
