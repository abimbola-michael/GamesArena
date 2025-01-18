import 'package:firebase_database/firebase_database.dart';

import '../../../shared/models/event_change.dart';

extension DatabaseReferenceExtension<T> on DatabaseReference {
  Query getQuery(List<dynamic>? where, List<dynamic>? order,
      List<dynamic>? start, List<dynamic>? end, List<dynamic>? limit) {
    Query query = this;
    // if (where != null) {
    //   int times = (where.length / 3).floor();
    //   for (int i = 0; i < times; i++) {
    //     final j = i * 3;
    //     String name = where[j + 0];
    //     String clause = where[j + 1];
    //     dynamic value = where[j + 2];

    //     query = query.where(
    //       name,
    //       isEqualTo: clause == "==" ? value : null,
    //       isNotEqualTo: clause == "!=" ? value : null,
    //       isLessThan: clause == "<" ? value : null,
    //       isGreaterThan: clause == ">" ? value : null,
    //       isLessThanOrEqualTo: clause == "<=" ? value : null,
    //       isGreaterThanOrEqualTo: clause == ">=" ? value : null,
    //       whereIn: clause == "in" ? value : null,
    //       whereNotIn: clause == "notin" ? value : null,
    //       arrayContains: clause == "contains" ? value : null,
    //       arrayContainsAny: clause == "containsany" ? value : null,
    //       isNull: clause == "is" ? value : null,
    //     );
    //   }
    // }
    if (where != null) {
      if (where.length % 3 == 0) {
        int times = where[1] == "==" ? 1 : where.length ~/ 3;
        for (int i = 0; i < times; i++) {
          final j = i * 3;
          String name = where[j + 0];
          String clause = where[j + 1];
          dynamic value = where[j + 2];

          if (clause == "==") {
            if (i == 0) {
              query = orderByChild(name).equalTo(value);
            } else {
              query = query.equalTo(value);
            }
          }
          // if (clause == "!="){
          //   query = query.equalTo(value);
          // }
          // query = query.where(
          //   name,
          //   isEqualTo: clause == "==" ? value : null,
          //   isNotEqualTo: clause == "!=" ? value : null,
          //   isLessThan: clause == "<" ? value : null,
          //   isGreaterThan: clause == ">" ? value : null,
          //   isLessThanOrEqualTo: clause == "<=" ? value : null,
          //   isGreaterThanOrEqualTo: clause == ">=" ? value : null,
          //   whereIn: clause == "in" ? value : null,
          //   whereNotIn: clause == "notin" ? value : null,
          //   arrayContains: clause == "contains" ? value : null,
          //   arrayContainsAny: clause == "containsany" ? value : null,
          //   isNull: clause == "null" ? value : null,
          // );
        }
      }
    }
    if (order != null) {
      String orderName = order[0];
      bool desc = order[1] ?? false;
      query = query.orderByChild(orderName);
    }
    if (start != null) {
      dynamic startName = start[0];
      bool after = start[1] ?? false;
      query =
          after ? query.startAfter([startName]) : query.startAt([startName]);
    }
    if (end != null) {
      dynamic endName = end[0];
      bool before = end[1] ?? false;
      query = before ? query.endBefore([endName]) : query.endAt([endName]);
    }
    if (limit != null) {
      int limitCount = limit[0];
      bool last = limit[1] ?? false;
      query =
          last ? query.limitToLast(limitCount) : query.limitToFirst(limitCount);
    }
    return query;
  }
}

extension DatabaseEventExtension<T> on DatabaseEvent {
  T? getValue<T>(T Function(Map<String, dynamic> map) callback) =>
      snapshot.map != null ? callback(snapshot.map!) : null;

  List<T> getValues<T>(T Function(Map<String, dynamic> map) callback) =>
      snapshot.children.isNotEmpty
          ? snapshot.children.map((value) => callback(value.map!)).toList()
          : [];

  List<EventChange<T>> getValuesChanges<T>(
      T Function(Map<String, dynamic> map) callback) {
    return snapshot.children.isNotEmpty
        ? snapshot.children
            .map(
                (value) => EventChange(type: type, value: callback(value.map!)))
            .toList()
        : [];
  }
}

extension MapExtension on Map {
  Map<String, dynamic> toStringMap() => cast<String, dynamic>();
  Map<String, dynamic> removeNull() {
    Map<String, dynamic> map = {};
    for (var entry in entries) {
      if (entry.value != null && entry.key != null) {
        map[entry.key] = entry.value;
      }
    }
    return map;
  }
}

extension DataSnapshotExtension<T> on DataSnapshot {
  Map<String, dynamic>? get map =>
      value != null ? (value as Map).toStringMap() : null;

  // Map<String, dynamic>? get map =>
  //     value != null ? (value as Map<String, dynamic>) : null;
  T? getValue<T>(T Function(Map<String, dynamic> map) callback) =>
      map != null ? callback(map!) : null;

  List<T> getValues<T>(T Function(Map<String, dynamic> map) callback) =>
      children.isNotEmpty
          ? children.map((value) => callback(value.map!)).toList()
          : [];
}
