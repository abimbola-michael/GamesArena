// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:gamesarena/enums/emums.dart';

class XandOTile {
  int x, y;
  String id;
  XandOChar? char;
  XandOTile(this.char, this.x, this.y, this.id);

  @override
  String toString() => 'XandOTile(y: $y, id: $id, char: $char)';
}

class XandODetails {
  int playPos;
  String? move;
  XandODetails({
    required this.playPos,
    this.move,
  });

  XandODetails copyWith({
    int? playPos,
    String? move,
  }) {
    return XandODetails(
      playPos: playPos ?? this.playPos,
      move: move ?? this.move,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'playPos': playPos,
      'move': move,
    };
  }

  factory XandODetails.fromMap(Map<String, dynamic> map) {
    return XandODetails(
      playPos: map['playPos'] as int,
      move: map['move'] != null ? map['move'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory XandODetails.fromJson(String source) =>
      XandODetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'XandODetails(playPos: $playPos, move: $move)';

  @override
  bool operator ==(covariant XandODetails other) {
    if (identical(this, other)) return true;

    return other.playPos == playPos && other.move == move;
  }

  @override
  int get hashCode => playPos.hashCode ^ move.hashCode;
}
