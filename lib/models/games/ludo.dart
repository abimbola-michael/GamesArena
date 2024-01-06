// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';

class Ludo {
  String id;
  int step;
  int x;
  int y;
  int houseIndex;
  int currentHouseIndex;
  Ludo(
    this.id,
    this.step,
    this.x,
    this.y,
    this.houseIndex,
    this.currentHouseIndex,
  );

  @override
  String toString() {
    return 'Ludo(id: $id, step: $step, x: $x, y: $y, houseIndex: $houseIndex, currentHouseIndex: $currentHouseIndex)';
  }

  Ludo copyWith({
    String? id,
    int? step,
    int? x,
    int? y,
    int? houseIndex,
    int? currentHouseIndex,
  }) {
    return Ludo(
      id ?? this.id,
      step ?? this.step,
      x ?? this.x,
      y ?? this.y,
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
      'houseIndex': houseIndex,
      'currentHouseIndex': currentHouseIndex,
    };
  }

  factory Ludo.fromMap(Map<String, dynamic> map) {
    return Ludo(
      (map["id"] ?? '') as String,
      (map["step"] ?? 0) as int,
      (map["x"] ?? 0) as int,
      (map["y"] ?? 0) as int,
      (map["houseIndex"] ?? 0) as int,
      (map["currentHouseIndex"] ?? 0) as int,
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
        other.houseIndex == houseIndex &&
        other.currentHouseIndex == currentHouseIndex;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        step.hashCode ^
        x.hashCode ^
        y.hashCode ^
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
  String currentPlayerId;
  String ludoIndices;
  int playPos;
  int playHouseIndex;
  int dice1;
  int dice2;
  bool selectedFromHouse;
  bool enteredHouse;
  LudoDetails({
    required this.currentPlayerId,
    required this.ludoIndices,
    required this.playPos,
    required this.playHouseIndex,
    required this.dice1,
    required this.dice2,
    required this.selectedFromHouse,
    required this.enteredHouse,
  });

  LudoDetails copyWith({
    String? currentPlayerId,
    String? ludoIndices,
    int? playPos,
    int? playHouseIndex,
    int? dice1,
    int? dice2,
    bool? selectedFromHouse,
    bool? enteredHouse,
  }) {
    return LudoDetails(
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      ludoIndices: ludoIndices ?? this.ludoIndices,
      playPos: playPos ?? this.playPos,
      playHouseIndex: playHouseIndex ?? this.playHouseIndex,
      dice1: dice1 ?? this.dice1,
      dice2: dice2 ?? this.dice2,
      selectedFromHouse: selectedFromHouse ?? this.selectedFromHouse,
      enteredHouse: enteredHouse ?? this.enteredHouse,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'currentPlayerId': currentPlayerId,
      'ludoIndices': ludoIndices,
      'playPos': playPos,
      'playHouseIndex': playHouseIndex,
      'dice1': dice1,
      'dice2': dice2,
      'selectedFromHouse': selectedFromHouse,
      'enteredHouse': enteredHouse,
    };
  }

  factory LudoDetails.fromMap(Map<String, dynamic> map) {
    return LudoDetails(
      currentPlayerId: (map["currentPlayerId"] ?? '') as String,
      ludoIndices: (map["ludoIndices"] ?? '') as String,
      playPos: (map["playPos"] ?? 0) as int,
      playHouseIndex: (map["playHouseIndex"] ?? 0) as int,
      dice1: (map["dice1"] ?? 0) as int,
      dice2: (map["dice2"] ?? 0) as int,
      selectedFromHouse: (map["selectedFromHouse"] ?? false) as bool,
      enteredHouse: (map["enteredHouse"] ?? false) as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory LudoDetails.fromJson(String source) =>
      LudoDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LudoDetails(currentPlayerId: $currentPlayerId, ludoIndices: $ludoIndices, playPos: $playPos, playHouseIndex: $playHouseIndex, dice1: $dice1, dice2: $dice2, selectedFromHouse: $selectedFromHouse, enteredHouse: $enteredHouse)';
  }

  @override
  bool operator ==(covariant LudoDetails other) {
    if (identical(this, other)) return true;

    return other.currentPlayerId == currentPlayerId &&
        other.ludoIndices == ludoIndices &&
        other.playPos == playPos &&
        other.playHouseIndex == playHouseIndex &&
        other.dice1 == dice1 &&
        other.dice2 == dice2 &&
        other.selectedFromHouse == selectedFromHouse &&
        other.enteredHouse == enteredHouse;
  }

  @override
  int get hashCode {
    return currentPlayerId.hashCode ^
        ludoIndices.hashCode ^
        playPos.hashCode ^
        playHouseIndex.hashCode ^
        dice1.hashCode ^
        dice2.hashCode ^
        selectedFromHouse.hashCode ^
        enteredHouse.hashCode;
  }
}
