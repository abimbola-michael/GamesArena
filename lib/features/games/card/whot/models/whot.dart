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
  String? whotIndices;
  int? playPos;
  WhotDetails({
    this.whotIndices,
    this.playPos,
  });

  WhotDetails copyWith({
    String? whotIndices,
    int? playPos,
  }) {
    return WhotDetails(
      whotIndices: whotIndices ?? this.whotIndices,
      playPos: playPos ?? this.playPos,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'whotIndices': whotIndices,
      'playPos': playPos,
    };
  }

  factory WhotDetails.fromMap(Map<String, dynamic> map) {
    return WhotDetails(
      whotIndices:
          map['whotIndices'] != null ? map['whotIndices'] as String : null,
      playPos: map['playPos'] != null ? map['playPos'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WhotDetails.fromJson(String source) =>
      WhotDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'WhotDetails(whotIndices: $whotIndices, playPos: $playPos)';

  @override
  bool operator ==(covariant WhotDetails other) {
    if (identical(this, other)) return true;

    return other.whotIndices == whotIndices && other.playPos == playPos;
  }

  @override
  int get hashCode => whotIndices.hashCode ^ playPos.hashCode;
}
