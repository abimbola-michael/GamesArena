// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:gamesarena/enums/emums.dart';

class XandO {
  int x, y;
  String id;
  XandOChar char;
  XandO(this.char, this.x, this.y, this.id);
}

class XandODetails {
  String currentPlayerId;
  int playPos;
  XandODetails({
    required this.currentPlayerId,
    required this.playPos,
  });

  XandODetails copyWith({
    String? currentPlayerId,
    int? playPos,
  }) {
    return XandODetails(
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

  factory XandODetails.fromMap(Map<String, dynamic> map) {
    return XandODetails(
      currentPlayerId: (map["currentPlayerId"] ?? '') as String,
      playPos: (map["playPos"] ?? 0) as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory XandODetails.fromJson(String source) =>
      XandODetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'XandODetails(currentPlayerId: $currentPlayerId, playPos: $playPos)';

  @override
  bool operator ==(covariant XandODetails other) {
    if (identical(this, other)) return true;

    return other.currentPlayerId == currentPlayerId && other.playPos == playPos;
  }

  @override
  int get hashCode => currentPlayerId.hashCode ^ playPos.hashCode;
}
