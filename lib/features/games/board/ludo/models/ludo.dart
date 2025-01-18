// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

class Ludo {
  String id;
  int step;
  int x;
  int y;
  int housePos;
  int houseIndex;
  int currentHouseIndex;
  Ludo(
    this.id,
    this.step,
    this.x,
    this.y,
    this.housePos,
    this.houseIndex,
    this.currentHouseIndex,
  );

  @override
  String toString() {
    return 'Ludo(id: $id, step: $step, x: $x, y: $y, housePos: $housePos, houseIndex: $houseIndex, currentHouseIndex: $currentHouseIndex)';
  }

  Ludo copyWith({
    String? id,
    int? step,
    int? x,
    int? y,
    int? housePos,
    int? houseIndex,
    int? currentHouseIndex,
  }) {
    return Ludo(
      id ?? this.id,
      step ?? this.step,
      x ?? this.x,
      y ?? this.y,
      housePos ?? this.housePos,
      houseIndex ?? this.houseIndex,
      currentHouseIndex ?? this.currentHouseIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'step': step,
      'x': x,
      'y': y,
      'housePos': housePos,
      'houseIndex': houseIndex,
      'currentHouseIndex': currentHouseIndex,
    };
  }

  factory Ludo.fromMap(Map<String, dynamic> map) {
    return Ludo(
      map['id'] as String,
      map['step'] as int,
      map['x'] as int,
      map['y'] as int,
      map['housePos'] as int,
      map['houseIndex'] as int,
      map['currentHouseIndex'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory Ludo.fromJson(String source) =>
      Ludo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant Ludo other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.step == step &&
        other.x == x &&
        other.y == y &&
        other.housePos == housePos &&
        other.houseIndex == houseIndex &&
        other.currentHouseIndex == currentHouseIndex;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        step.hashCode ^
        x.hashCode ^
        y.hashCode ^
        housePos.hashCode ^
        houseIndex.hashCode ^
        currentHouseIndex.hashCode;
  }
}

class LudoTile {
  int x;
  int y;
  String id;
  List<Ludo> ludos;
  int houseIndex;
  LudoTile(
    this.x,
    this.y,
    this.id,
    this.ludos,
    this.houseIndex,
  );

  LudoTile copyWith({
    int? x,
    int? y,
    String? id,
    List<Ludo>? ludos,
    int? houseIndex,
  }) {
    return LudoTile(
      x ?? this.x,
      y ?? this.y,
      id ?? this.id,
      ludos ?? this.ludos,
      houseIndex ?? this.houseIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'x': x,
      'y': y,
      'id': id,
      'ludos': ludos.map((x) {
        return x.toMap();
      }).toList(growable: false),
      'houseIndex': houseIndex,
    };
  }

  factory LudoTile.fromMap(Map<String, dynamic> map) {
    return LudoTile(
      (map["x"] ?? 0) as int,
      (map["y"] ?? 0) as int,
      (map["id"] ?? '') as String,
      List<Ludo>.from(
        ((map['ludos'] ?? const <Ludo>[]) as List).map<Ludo>((x) {
          return Ludo.fromMap(
              (x ?? Map<String, dynamic>.from({})) as Map<String, dynamic>);
        }),
      ),
      (map["houseIndex"] ?? 0) as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory LudoTile.fromJson(String source) =>
      LudoTile.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LudoTile(x: $x, y: $y, id: $id, ludos: $ludos, houseIndex: $houseIndex)';
  }

  @override
  bool operator ==(covariant LudoTile other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.x == x &&
        other.y == y &&
        other.id == id &&
        listEquals(other.ludos, ludos) &&
        other.houseIndex == houseIndex;
  }

  @override
  int get hashCode {
    return x.hashCode ^
        y.hashCode ^
        id.hashCode ^
        ludos.hashCode ^
        houseIndex.hashCode;
  }
}

class LudoDetails {
  String? ludoIndices;
  int? pos;
  int? housePos;
  int? dice1;
  int? dice2;
  bool? selectedFromHouse;
  bool? enteredHouse;
  LudoDetails({
    this.ludoIndices,
    this.pos,
    this.housePos,
    this.dice1,
    this.dice2,
    this.selectedFromHouse,
    this.enteredHouse,
  });

  LudoDetails copyWith({
    String? ludoIndices,
    int? pos,
    int? housePos,
    int? dice1,
    int? dice2,
    bool? selectedFromHouse,
    bool? enteredHouse,
  }) {
    return LudoDetails(
      ludoIndices: ludoIndices ?? this.ludoIndices,
      pos: pos ?? this.pos,
      housePos: housePos ?? this.housePos,
      dice1: dice1 ?? this.dice1,
      dice2: dice2 ?? this.dice2,
      selectedFromHouse: selectedFromHouse ?? this.selectedFromHouse,
      enteredHouse: enteredHouse ?? this.enteredHouse,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ludoIndices': ludoIndices,
      'pos': pos,
      'housePos': housePos,
      'dice1': dice1,
      'dice2': dice2,
      'selectedFromHouse': selectedFromHouse,
      'enteredHouse': enteredHouse,
    };
  }

  factory LudoDetails.fromMap(Map<String, dynamic> map) {
    return LudoDetails(
      ludoIndices:
          map['ludoIndices'] != null ? map['ludoIndices'] as String : null,
      pos: map['pos'] != null ? map['pos'] as int : null,
      housePos: map['housePos'] != null ? map['housePos'] as int : null,
      dice1: map['dice1'] != null ? map['dice1'] as int : null,
      dice2: map['dice2'] != null ? map['dice2'] as int : null,
      selectedFromHouse: map['selectedFromHouse'] != null
          ? map['selectedFromHouse'] as bool
          : null,
      enteredHouse:
          map['enteredHouse'] != null ? map['enteredHouse'] as bool : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LudoDetails.fromJson(String source) =>
      LudoDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LudoDetails(ludoIndices: $ludoIndices, pos: $pos, housePos: $housePos, dice1: $dice1, dice2: $dice2, selectedFromHouse: $selectedFromHouse, enteredHouse: $enteredHouse)';
  }

  @override
  bool operator ==(covariant LudoDetails other) {
    if (identical(this, other)) return true;

    return other.ludoIndices == ludoIndices &&
        other.pos == pos &&
        other.housePos == housePos &&
        other.dice1 == dice1 &&
        other.dice2 == dice2 &&
        other.selectedFromHouse == selectedFromHouse &&
        other.enteredHouse == enteredHouse;
  }

  @override
  int get hashCode {
    return ludoIndices.hashCode ^
        pos.hashCode ^
        housePos.hashCode ^
        dice1.hashCode ^
        dice2.hashCode ^
        selectedFromHouse.hashCode ^
        enteredHouse.hashCode;
  }
}
