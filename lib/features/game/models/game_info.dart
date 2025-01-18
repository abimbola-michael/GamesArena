// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';

class GameInfo {
  String about;
  List<String> rules;
  List<String> howtoplay;
  GameInfo({
    required this.about,
    required this.rules,
    required this.howtoplay,
  });

  GameInfo copyWith({
    String? about,
    List<String>? rules,
    List<String>? howtoplay,
  }) {
    return GameInfo(
      about: about ?? this.about,
      rules: rules ?? this.rules,
      howtoplay: howtoplay ?? this.howtoplay,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'about': about,
      'rules': rules,
      'howtoplay': howtoplay,
    };
  }

  factory GameInfo.fromMap(Map<String, dynamic> map) {
    return GameInfo(
      about: (map["about"] ?? '') as String,
      rules: List<String>.from(
        ((map['rules'] ?? const <String>[]) as List<String>),
      ),
      howtoplay: List<String>.from(
        ((map['howtoplay'] ?? const <String>[]) as List<String>),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory GameInfo.fromJson(String source) =>
      GameInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'GameInfo(about: $about, rules: $rules, howtoplay: $howtoplay)';

  @override
  bool operator ==(covariant GameInfo other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.about == about &&
        listEquals(other.rules, rules) &&
        listEquals(other.howtoplay, howtoplay);
  }

  @override
  int get hashCode => about.hashCode ^ rules.hashCode ^ howtoplay.hashCode;
}
