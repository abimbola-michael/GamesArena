// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Draught {
  int x;
  int y;
  String id;
  int player;
  int color;
  bool king;
  Draught(
    this.x,
    this.y,
    this.id,
    this.player,
    this.color,
    this.king,
  );

  @override
  String toString() {
    return 'Draught(x: $x, y: $y, id: $id, player: $player, color: $color, king: $king)';
  }

  Draught copyWith({
    int? x,
    int? y,
    String? id,
    int? player,
    int? color,
    bool? king,
  }) {
    return Draught(
      x ?? this.x,
      y ?? this.y,
      id ?? this.id,
      player ?? this.player,
      color ?? this.color,
      king ?? this.king,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'x': x,
      'y': y,
      'id': id,
      'player': player,
      'color': color,
      'king': king,
    };
  }

  factory Draught.fromMap(Map<String, dynamic> map) {
    return Draught(
      (map["x"] ?? 0) as int,
      (map["y"] ?? 0) as int,
      (map["id"] ?? '') as String,
      (map["player"] ?? 0) as int,
      (map["color"] ?? 0) as int,
      (map["king"] ?? false) as bool,
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
        other.color == color &&
        other.king == king;
  }

  @override
  int get hashCode {
    return x.hashCode ^
        y.hashCode ^
        id.hashCode ^
        player.hashCode ^
        color.hashCode ^
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
  String currentPlayerId;
  int playPos;
  DraughtDetails({
    required this.currentPlayerId,
    required this.playPos,
  });

  DraughtDetails copyWith({
    String? currentPlayerId,
    int? playPos,
  }) {
    return DraughtDetails(
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

  factory DraughtDetails.fromMap(Map<String, dynamic> map) {
    return DraughtDetails(
      currentPlayerId: (map["currentPlayerId"] ?? '') as String,
      playPos: (map["playPos"] ?? 0) as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory DraughtDetails.fromJson(String source) =>
      DraughtDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'DraughtDetails(currentPlayerId: $currentPlayerId, playPos: $playPos)';

  @override
  bool operator ==(covariant DraughtDetails other) {
    if (identical(this, other)) return true;

    return other.currentPlayerId == currentPlayerId && other.playPos == playPos;
  }

  @override
  int get hashCode => currentPlayerId.hashCode ^ playPos.hashCode;
}
