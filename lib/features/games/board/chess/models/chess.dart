// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:gamesarena/enums/emums.dart';

class Chess {
  int x;
  int y;
  String id;
  int player;
  ChessShape shape;
  bool moved;
  Chess({
    required this.x,
    required this.y,
    required this.id,
    required this.player,
    required this.moved,
    required this.shape,
  });

  Chess copyWith({
    int? x,
    int? y,
    String? id,
    int? player,
    bool? moved,
  }) {
    return Chess(
      x: x ?? this.x,
      y: y ?? this.y,
      id: id ?? this.id,
      player: player ?? this.player,
      moved: moved ?? this.moved,
      shape: shape ?? this.shape,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'x': x,
      'y': y,
      'id': id,
      'player': player,
      'moved': moved,
    };
  }

  factory Chess.fromMap(Map<String, dynamic> map) {
    return Chess(
      x: map['x'] as int,
      y: map['y'] as int,
      id: map['id'] as String,
      player: map['player'] as int,
      moved: map['moved'] as bool,
      shape: map['shape'] as ChessShape,
    );
  }

  String toJson() => json.encode(toMap());

  factory Chess.fromJson(String source) =>
      Chess.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Chess(x: $x, y: $y, id: $id, player: $player, moved: $moved)';
  }

  @override
  bool operator ==(covariant Chess other) {
    if (identical(this, other)) return true;

    return other.x == x &&
        other.y == y &&
        other.id == id &&
        other.player == player &&
        other.moved == moved;
  }

  @override
  int get hashCode {
    return x.hashCode ^
        y.hashCode ^
        id.hashCode ^
        player.hashCode ^
        moved.hashCode;
  }
}

class ChessTile {
  int x;
  int y;
  String id;
  Chess? chess;
  ChessTile(
    this.x,
    this.y,
    this.id,
    this.chess,
  );

  ChessTile copyWith({
    int? x,
    int? y,
    String? id,
    Chess? chess,
  }) {
    return ChessTile(
      x ?? this.x,
      y ?? this.y,
      id ?? this.id,
      chess ?? this.chess,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'x': x,
      'y': y,
      'id': id,
      'chess': chess?.toMap(),
    };
  }

  factory ChessTile.fromMap(Map<String, dynamic> map) {
    return ChessTile(
      (map["x"] ?? 0) as int,
      (map["y"] ?? 0) as int,
      (map["id"] ?? '') as String,
      map['chess'] != null
          ? Chess.fromMap((map["chess"] ?? Map<String, dynamic>.from({}))
              as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChessTile.fromJson(String source) =>
      ChessTile.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ChessTile(x: $x, y: $y, id: $id, chess: $chess)';
  }

  @override
  bool operator ==(covariant ChessTile other) {
    if (identical(this, other)) return true;

    return other.x == x &&
        other.y == y &&
        other.id == id &&
        other.chess == chess;
  }

  @override
  int get hashCode {
    return x.hashCode ^ y.hashCode ^ id.hashCode ^ chess.hashCode;
  }
}

class ChessDetails {
  int pos;
  ChessDetails({
    required this.pos,
  });

  ChessDetails copyWith({
    int? pos,
  }) {
    return ChessDetails(
      pos: pos ?? this.pos,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pos': pos,
    };
  }

  factory ChessDetails.fromMap(Map<String, dynamic> map) {
    return ChessDetails(
      pos: map['pos'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChessDetails.fromJson(String source) =>
      ChessDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'ChessDetails(pos: $pos)';

  @override
  bool operator ==(covariant ChessDetails other) {
    if (identical(this, other)) return true;

    return other.pos == pos;
  }

  @override
  int get hashCode => pos.hashCode;
}
