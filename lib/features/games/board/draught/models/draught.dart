// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class Draught {
  int x;
  int y;
  String id;
  int player;
  bool king;
  Draught(
    this.x,
    this.y,
    this.id,
    this.player,
    this.king,
  );

  @override
  String toString() {
    return 'Draught(x: $x, y: $y, id: $id, player: $player, king: $king)';
  }

  Draught copyWith({
    int? x,
    int? y,
    String? id,
    int? player,
    bool? king,
  }) {
    return Draught(
      x ?? this.x,
      y ?? this.y,
      id ?? this.id,
      player ?? this.player,
      king ?? this.king,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'x': x,
      'y': y,
      'id': id,
      'player': player,
      'king': king,
    };
  }

  factory Draught.fromMap(Map<String, dynamic> map) {
    return Draught(
      map['x'] as int,
      map['y'] as int,
      map['id'] as String,
      map['player'] as int,
      map['king'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory Draught.fromJson(String source) =>
      Draught.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant Draught other) {
    if (identical(this, other)) return true;

    return other.x == x &&
        other.y == y &&
        other.id == id &&
        other.player == player &&
        other.king == king;
  }

  @override
  int get hashCode {
    return x.hashCode ^
        y.hashCode ^
        id.hashCode ^
        player.hashCode ^
        king.hashCode;
  }
}

class DraughtTile {
  int x;
  int y;
  String id;
  Draught? draught;
  DraughtTile(
    this.x,
    this.y,
    this.id,
    this.draught,
  );

  @override
  String toString() {
    return 'DraughtTile(x: $x, y: $y, id: $id, draught: $draught)';
  }

  DraughtTile copyWith({
    int? x,
    int? y,
    String? id,
    Draught? draught,
  }) {
    return DraughtTile(
      x ?? this.x,
      y ?? this.y,
      id ?? this.id,
      draught ?? this.draught,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'x': x,
      'y': y,
      'id': id,
      'draught': draught?.toMap(),
    };
  }

  factory DraughtTile.fromMap(Map<String, dynamic> map) {
    return DraughtTile(
      (map["x"] ?? 0) as int,
      (map["y"] ?? 0) as int,
      (map["id"] ?? '') as String,
      map['draught'] != null
          ? Draught.fromMap((map["draught"] ?? Map<String, dynamic>.from({}))
              as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DraughtTile.fromJson(String source) =>
      DraughtTile.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant DraughtTile other) {
    if (identical(this, other)) return true;

    return other.x == x &&
        other.y == y &&
        other.id == id &&
        other.draught == draught;
  }

  @override
  int get hashCode {
    return x.hashCode ^ y.hashCode ^ id.hashCode ^ draught.hashCode;
  }
}

class DraughtDetails {
  int? pos;
  int? startPos;
  int? endPos;
  List<int>? poses;
  String? move;
  DraughtDetails({
    this.pos,
    this.startPos,
    this.endPos,
    this.poses,
    this.move,
  });

  DraughtDetails copyWith({
    int? pos,
    int? startPos,
    int? endPos,
    List<int>? poses,
    String? move,
  }) {
    return DraughtDetails(
      pos: pos ?? this.pos,
      startPos: startPos ?? this.startPos,
      endPos: endPos ?? this.endPos,
      poses: poses ?? this.poses,
      move: move ?? this.move,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pos': pos,
      'startPos': startPos,
      'endPos': endPos,
      'poses': poses,
      'move': move,
    };
  }

  factory DraughtDetails.fromMap(Map<String, dynamic> map) {
    return DraughtDetails(
      pos: map['pos'] != null ? map['pos'] as int : null,
      startPos: map['startPos'] != null ? map['startPos'] as int : null,
      endPos: map['endPos'] != null ? map['endPos'] as int : null,
      poses: map['poses'] != null
          ? List<int>.from((map['poses'] as List<dynamic>))
          : null,
      move: map['move'] != null ? map['move'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DraughtDetails.fromJson(String source) =>
      DraughtDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'DraughtDetails(pos: $pos, startPos: $startPos, endPos: $endPos, poses: $poses, move: $move)';
  }

  @override
  bool operator ==(covariant DraughtDetails other) {
    if (identical(this, other)) return true;

    return other.pos == pos &&
        other.startPos == startPos &&
        other.endPos == endPos &&
        listEquals(other.poses, poses) &&
        other.move == move;
  }

  @override
  int get hashCode {
    return pos.hashCode ^
        startPos.hashCode ^
        endPos.hashCode ^
        poses.hashCode ^
        move.hashCode;
  }
}
