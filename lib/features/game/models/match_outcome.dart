// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class MatchOutcome {
  String outcome;
  List<String> winners;
  List<String> others;
  List<int> winnersIndices;
  List<int> othersIndices;
  int pageIndex = 0;
  MatchOutcome({
    required this.outcome,
    required this.winners,
    required this.others,
    required this.winnersIndices,
    required this.othersIndices,
  });

  MatchOutcome copyWith({
    String? outcome,
    List<String>? winners,
    List<String>? others,
    List<int>? winnersIndices,
    List<int>? othersIndices,
  }) {
    return MatchOutcome(
      outcome: outcome ?? this.outcome,
      winners: winners ?? this.winners,
      others: others ?? this.others,
      winnersIndices: winnersIndices ?? this.winnersIndices,
      othersIndices: othersIndices ?? this.othersIndices,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'outcome': outcome,
      'winners': winners,
      'others': others,
      'winnersIndices': winnersIndices,
      'othersIndices': othersIndices,
    };
  }

  factory MatchOutcome.fromMap(Map<String, dynamic> map) {
    return MatchOutcome(
      outcome: map['outcome'] as String,
      winners: List<String>.from((map['winners'] as List<dynamic>)),
      others: List<String>.from((map['others'] as List<dynamic>)),
      winnersIndices: List<int>.from((map['winnersIndices'] as List<int>)),
      othersIndices: List<int>.from((map['othersIndices'] as List<int>)),
    );
  }

  String toJson() => json.encode(toMap());

  factory MatchOutcome.fromJson(String source) =>
      MatchOutcome.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MatchOutcome(outcome: $outcome, winners: $winners, others: $others, winnersIndices: $winnersIndices, othersIndices: $othersIndices)';
  }

  @override
  bool operator ==(covariant MatchOutcome other) {
    if (identical(this, other)) return true;

    return other.outcome == outcome &&
        listEquals(other.winners, winners) &&
        listEquals(other.others, others) &&
        listEquals(other.winnersIndices, winnersIndices) &&
        listEquals(other.othersIndices, othersIndices);
  }

  @override
  int get hashCode {
    return outcome.hashCode ^
        winners.hashCode ^
        others.hashCode ^
        winnersIndices.hashCode ^
        othersIndices.hashCode;
  }
}
