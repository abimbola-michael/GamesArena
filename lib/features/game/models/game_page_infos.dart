// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';

class GamePageInfos {
  int totalPages;
  int currentPage;
  int lastRecordId;
  int lastRecordIdRoundId;
  GamePageInfos({
    required this.totalPages,
    required this.currentPage,
    required this.lastRecordId,
    required this.lastRecordIdRoundId,
  });

  GamePageInfos copyWith({
    int? totalPages,
    int? currentPage,
    int? lastRecordId,
    int? lastRecordIdRoundId,
  }) {
    return GamePageInfos(
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      lastRecordId: lastRecordId ?? this.lastRecordId,
      lastRecordIdRoundId: lastRecordIdRoundId ?? this.lastRecordIdRoundId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalPages': totalPages,
      'currentPage': currentPage,
      'lastRecordId': lastRecordId,
      'lastRecordIdRoundId': lastRecordIdRoundId,
    };
  }

  factory GamePageInfos.fromMap(Map<String, dynamic> map) {
    return GamePageInfos(
      totalPages: map['totalPages'] as int,
      currentPage: map['currentPage'] as int,
      lastRecordId: map['lastRecordId'] as int,
      lastRecordIdRoundId: map['lastRecordIdRoundId'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory GamePageInfos.fromJson(String source) =>
      GamePageInfos.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'GamePageInfos(totalPages: $totalPages, currentPage: $currentPage, lastRecordId: $lastRecordId, lastRecordIdRoundId: $lastRecordIdRoundId)';
  }

  @override
  bool operator ==(covariant GamePageInfos other) {
    if (identical(this, other)) return true;

    return other.totalPages == totalPages &&
        other.currentPage == currentPage &&
        other.lastRecordId == lastRecordId &&
        other.lastRecordIdRoundId == lastRecordIdRoundId;
  }

  @override
  int get hashCode {
    return totalPages.hashCode ^
        currentPage.hashCode ^
        lastRecordId.hashCode ^
        lastRecordIdRoundId.hashCode;
  }
}
