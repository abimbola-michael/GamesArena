// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:gamesarena/enums/emums.dart';

class XandOTile {
  int x, y;
  String id;
  XandOChar? char;
  XandOTile(this.char, this.x, this.y, this.id);
}

class XandODetails {
  int playPos;
  XandODetails({
    required this.playPos,
  });

  XandODetails copyWith({
    int? playPos,
  }) {
    return XandODetails(
      playPos: playPos ?? this.playPos,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'playPos': playPos,
    };
  }

  factory XandODetails.fromMap(Map<String, dynamic> map) {
    return XandODetails(
      playPos: map['playPos'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory XandODetails.fromJson(String source) =>
      XandODetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'XandODetails(playPos: $playPos)';

  @override
  bool operator ==(covariant XandODetails other) {
    if (identical(this, other)) return true;

    return other.playPos == playPos;
  }

  @override
  int get hashCode => playPos.hashCode;
}
