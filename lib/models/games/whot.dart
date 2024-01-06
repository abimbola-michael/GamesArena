// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Whot {
  String id;
  int number;
  int shape;
  Whot(
    this.id,
    this.number,
    this.shape,
  );

  @override
  String toString() => 'Whot(id: $id, number: $number, shape: $shape)';

  Whot copyWith({
    String? id,
    int? number,
    int? shape,
  }) {
    return Whot(
      id ?? this.id,
      number ?? this.number,
      shape ?? this.shape,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'number': number,
      'shape': shape,
    };
  }

  factory Whot.fromMap(Map<String, dynamic> map) {
    return Whot(
      (map["id"] ?? '') as String,
      (map["number"] ?? 0) as int,
      (map["shape"] ?? 0) as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory Whot.fromJson(String source) =>
      Whot.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant Whot other) {
    if (identical(this, other)) return true;

    return other.id == id && other.number == number && other.shape == shape;
  }

  @override
  int get hashCode => id.hashCode ^ number.hashCode ^ shape.hashCode;
}

class WhotDetails {
  String currentPlayerId;
  String whotIndices;
  int playPos;
  int shapeNeeded;
  WhotDetails({
    required this.currentPlayerId,
    required this.whotIndices,
    required this.playPos,
    required this.shapeNeeded,
  });

  WhotDetails copyWith({
    String? currentPlayerId,
    String? whotIndices,
    int? playPos,
    int? shapeNeeded,
  }) {
    return WhotDetails(
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      whotIndices: whotIndices ?? this.whotIndices,
      playPos: playPos ?? this.playPos,
      shapeNeeded: shapeNeeded ?? this.shapeNeeded,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'currentPlayerId': currentPlayerId,
      'whotIndices': whotIndices,
      'playPos': playPos,
      'shapeNeeded': shapeNeeded,
    };
  }

  factory WhotDetails.fromMap(Map<String, dynamic> map) {
    return WhotDetails(
      currentPlayerId: (map["currentPlayerId"] ?? '') as String,
      whotIndices: (map["whotIndices"] ?? '') as String,
      playPos: (map["playPos"] ?? 0) as int,
      shapeNeeded: (map["shapeNeeded"] ?? 0) as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory WhotDetails.fromJson(String source) =>
      WhotDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WhotDetails(currentPlayerId: $currentPlayerId, whotIndices: $whotIndices, playPos: $playPos, shapeNeeded: $shapeNeeded)';
  }

  @override
  bool operator ==(covariant WhotDetails other) {
    if (identical(this, other)) return true;

    return other.currentPlayerId == currentPlayerId &&
        other.whotIndices == whotIndices &&
        other.playPos == playPos &&
        other.shapeNeeded == shapeNeeded;
  }

  @override
  int get hashCode {
    return currentPlayerId.hashCode ^
        whotIndices.hashCode ^
        playPos.hashCode ^
        shapeNeeded.hashCode;
  }
}
