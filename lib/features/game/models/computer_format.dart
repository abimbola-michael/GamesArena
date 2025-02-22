// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ComputerFormat {
  String model;
  String initialization;
  String conditions;
  String extras;
  ComputerFormat({
    required this.model,
    required this.initialization,
    required this.conditions,
    required this.extras,
  });

  ComputerFormat copyWith({
    String? model,
    String? initialization,
    String? conditions,
    String? extras,
  }) {
    return ComputerFormat(
      model: model ?? this.model,
      initialization: initialization ?? this.initialization,
      conditions: conditions ?? this.conditions,
      extras: extras ?? this.extras,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'model': model,
      'initialization': initialization,
      'conditions': conditions,
      'extras': extras,
    };
  }

  factory ComputerFormat.fromMap(Map<String, dynamic> map) {
    return ComputerFormat(
      model: map['model'] as String,
      initialization: map['initialization'] as String,
      conditions: map['conditions'] as String,
      extras: map['extras'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ComputerFormat.fromJson(String source) =>
      ComputerFormat.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ComputerFormat(model: $model, initialization: $initialization, conditions: $conditions, extras: $extras)';
  }

  @override
  bool operator ==(covariant ComputerFormat other) {
    if (identical(this, other)) return true;

    return other.model == model &&
        other.initialization == initialization &&
        other.conditions == conditions &&
        other.extras == extras;
  }

  @override
  int get hashCode {
    return model.hashCode ^
        initialization.hashCode ^
        conditions.hashCode ^
        extras.hashCode;
  }
}
