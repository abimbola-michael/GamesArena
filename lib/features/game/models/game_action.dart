// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'player.dart';

class GameAction {
  String action;
  String game;
  bool hasDetails;
  List<Player> players;
  Map<String, dynamic> args;
  GameAction({
    required this.action,
    required this.game,
    required this.hasDetails,
    required this.players,
    required this.args,
  });

  GameAction copyWith({
    String? action,
    String? game,
    bool? hasDetails,
    List<Player>? players,
    Map<String, dynamic>? args,
  }) {
    return GameAction(
      action: action ?? this.action,
      game: game ?? this.game,
      hasDetails: hasDetails ?? this.hasDetails,
      players: players ?? this.players,
      args: args ?? this.args,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'action': action,
      'game': game,
      'hasDetails': hasDetails,
      'players': players.map((x) => x.toMap()).toList(),
      'args': args,
    };
  }

  factory GameAction.fromMap(Map<String, dynamic> map) {
    return GameAction(
      action: map['action'] as String,
      game: map['game'] as String,
      hasDetails: map['hasDetails'] as bool,
      players: List<Player>.from(
        (map['players'] as List<dynamic>).map<Player>(
          (x) => Player.fromMap(x as Map<String, dynamic>),
        ),
      ),
      args: Map<String, dynamic>.from((map['args'] as Map<String, dynamic>)),
    );
  }

  String toJson() => json.encode(toMap());

  factory GameAction.fromJson(String source) =>
      GameAction.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'GameAction(action: $action, game: $game, hasDetails: $hasDetails, players: $players, args: $args)';
  }

  @override
  bool operator ==(covariant GameAction other) {
    if (identical(this, other)) return true;

    return other.action == action &&
        other.game == game &&
        other.hasDetails == hasDetails &&
        listEquals(other.players, players) &&
        mapEquals(other.args, args);
  }

  @override
  int get hashCode {
    return action.hashCode ^
        game.hashCode ^
        hasDetails.hashCode ^
        players.hashCode ^
        args.hashCode;
  }
}
