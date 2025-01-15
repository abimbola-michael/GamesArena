// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'exempt_player.dart';
import 'player.dart';

class GameAction {
  String action;
  String game;
  bool hasStarted;
  List<Player> players;
  List<ExemptPlayer> exemptPlayers;
  Map<String, dynamic> args;

  GameAction({
    required this.action,
    required this.game,
    required this.hasStarted,
    required this.players,
    required this.exemptPlayers,
    required this.args,
  });

  GameAction copyWith({
    String? action,
    String? game,
    bool? hasStarted,
    List<Player>? players,
    List<ExemptPlayer>? exemptPlayers,
    Map<String, dynamic>? args,
  }) {
    return GameAction(
      action: action ?? this.action,
      game: game ?? this.game,
      hasStarted: hasStarted ?? this.hasStarted,
      players: players ?? this.players,
      exemptPlayers: exemptPlayers ?? this.exemptPlayers,
      args: args ?? this.args,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'action': action,
      'game': game,
      'hasStarted': hasStarted,
      'players': players.map((x) => x.toMap()).toList(),
      'exemptPlayers': exemptPlayers.map((x) => x.toMap()).toList(),
      'args': args,
    };
  }

  factory GameAction.fromMap(Map<String, dynamic> map) {
    return GameAction(
      action: map['action'] as String,
      game: map['game'] as String,
      hasStarted: map['hasStarted'] as bool,
      players: List<Player>.from(
        (map['players'] as List<int>).map<Player>(
          (x) => Player.fromMap(x as Map<String, dynamic>),
        ),
      ),
      exemptPlayers: List<ExemptPlayer>.from(
        (map['exemptPlayers'] as List<dynamic>).map<ExemptPlayer>(
          (x) => ExemptPlayer.fromMap(x as Map<String, dynamic>),
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
    return 'GameAction(action: $action, game: $game, hasStarted: $hasStarted, players: $players, exemptPlayers: $exemptPlayers, args: $args)';
  }

  @override
  bool operator ==(covariant GameAction other) {
    if (identical(this, other)) return true;

    return other.action == action &&
        other.game == game &&
        other.hasStarted == hasStarted &&
        listEquals(other.players, players) &&
        listEquals(other.exemptPlayers, exemptPlayers) &&
        mapEquals(other.args, args);
  }

  @override
  int get hashCode {
    return action.hashCode ^
        game.hashCode ^
        hasStarted.hashCode ^
        players.hashCode ^
        exemptPlayers.hashCode ^
        args.hashCode;
  }
}
