// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:gamesarena/enums/emums.dart';

class Chess {
  int x;
  int y;
  String id;
  int player;
  int color;
  ChessShape shape;
  bool moved;
  Chess(
    this.x,
    this.y,
    this.id,
    this.player,
    this.color,
    this.shape,
    this.moved,
  );

  Chess copyWith({
    int? x,
    int? y,
    String? id,
    int? player,
    int? color,
    bool? moved,
  }) {
    return Chess(
      x ?? this.x,
      y ?? this.y,
      id ?? this.id,
      player ?? this.player,
      color ?? this.color,
      shape,
      moved ?? this.moved,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'x': x,
      'y': y,
      'id': id,
      'player': player,
      'color': color,
      'moved': moved,
    };
  }

  factory Chess.fromMap(Map<String, dynamic> map) {
    return Chess(
      (map["x"] ?? 0) as int,
      (map["y"] ?? 0) as int,
      (map["id"] ?? '') as String,
      (map["player"] ?? 0) as int,
      (map["color"] ?? 0) as int,
      (map["shape"] ?? ChessShape.pawn),
      (map["moved"] ?? false) as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory Chess.fromJson(String source) =>
      Chess.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Chess(x: $x, y: $y, id: $id, player: $player, color: $color, moved: $moved)';
  }

  @override
  bool operator ==(covariant Chess other) {
    if (identical(this, other)) return true;

    return other.x == x &&
        other.y == y &&
        other.id == id &&
        other.player == player &&
        other.color == color &&
        other.moved == moved;
  }

  @override
  int get hashCode {
    return x.hashCode ^
        y.hashCode ^
        id.hashCode ^
        player.hashCode ^
        color.hashCode ^
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
  String currentPlayerId;
  int playPos;
  ChessDetails({
    required this.currentPlayerId,
    required this.playPos,
  });

  ChessDetails copyWith({
    String? currentPlayerId,
    int? playPos,
  }) {
    return ChessDetails(
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      playPos: playPos ?? this.playPos,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'currentPlayerId': currentPlayerId,
      'playPos': playPos,
    };
  }

  factory ChessDetails.fromMap(Map<String, dynamic> map) {
    return ChessDetails(
      currentPlayerId: (map["currentPlayerId"] ?? '') as String,
      playPos: (map["playPos"] ?? 0) as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChessDetails.fromJson(String source) =>
      ChessDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ChessDetails(currentPlayerId: $currentPlayerId, playPos: $playPos)';

  @override
  bool operator ==(covariant ChessDetails other) {
    if (identical(this, other)) return true;

    return other.currentPlayerId == currentPlayerId && other.playPos == playPos;
  }

  @override
  int get hashCode => currentPlayerId.hashCode ^ playPos.hashCode;
}
