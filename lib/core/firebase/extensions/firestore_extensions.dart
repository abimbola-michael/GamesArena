import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_methods.dart';

extension DocsnapshotExtension<T> on DocumentSnapshot {
  Map<String, dynamic>? get map =>
      data() != null ? data() as Map<String, dynamic> : null;
  T? getValue<T>(T Function(Map<String, dynamic> map) callback) =>
      map != null ? callback(map!) : null;
}

extension QuerysnapshotExtension<T> on QuerySnapshot {
  List<T> getValues<T>(T Function(Map<String, dynamic> map) callback) =>
      docs.map((doc) => callback(doc.map!)).toList();
  List<ValueChange<T>> getValuesChange<T>(
          T Function(Map<String, dynamic> map) callback) =>
      docChanges
          .map((change) => ValueChange<T>(
                type: change.type,
                oldIndex: change.oldIndex,
                newIndex: change.newIndex,
                value: callback(change.doc.map!),
              ))
          .toList();
}

extension QueryExtension on Query {
  Query getQuery(
      List<dynamic>? queries,
      List<dynamic>? where,
      List<dynamic>? order,
      List<dynamic>? start,
      List<dynamic>? end,
      List<dynamic>? limit) {
    Query query = this;
    if (queries != null) {
      for (int i = 0; i < queries.length; i++) {
        final queryList = queries[i];
        if (queryList is! List || queryList.isEmpty) continue;

        List<dynamic>? where =
            queryList.first == "where" ? queryList.sublist(1) : null;
        List<dynamic>? order =
            queryList.first == "order" ? queryList.sublist(1) : null;
        List<dynamic>? start =
            queryList.first == "start" ? queryList.sublist(1) : null;
        List<dynamic>? end =
            queryList.first == "end" ? queryList.sublist(1) : null;
        List<dynamic>? limit =
            queryList.first == "limit" ? queryList.sublist(1) : null;
        // print("queryList = $queryList, $where, $order, $start, $end, $limit ");

        if (where != null &&
            where.isNotEmpty &&
            where[0] != null &&
            where.length % 3 == 0) {
          int times = (where.length / 3).floor();
          for (int i = 0; i < times; i++) {
            final j = i * 3;
            String name = where[j + 0];
            String clause = where[j + 1];
            dynamic value = where[j + 2];

            //if (value != null) {
            if (clause == "==") {
              query = query.where(name, isEqualTo: value);
            }
            if (clause == "!=") {
              query = query.where(name, isNotEqualTo: value);
            }
            if (clause == "<") {
              query = query.where(name, isLessThan: value);
            }
            if (clause == ">") {
              query = query.where(name, isGreaterThan: value);
            }
            if (clause == "<=") {
              query = query.where(name, isLessThanOrEqualTo: value);
            }
            if (clause == ">=") {
              query = query.where(name, isGreaterThanOrEqualTo: value);
            }
            if (clause == "in") {
              query = query.where(name, whereIn: value);
            }
            if (clause == "notin") {
              query = query.where(name, whereNotIn: value);
            }
            if (clause == "contains") {
              query = query.where(name, arrayContains: value);
            }
            if (clause == "containsany") {
              query = query.where(name, arrayContainsAny: value);
            }
            if (clause == "is") {
              query = query.where(name, isNull: value);
            }
            //}
          }
        }
        if (order != null && order.isNotEmpty && order[0] != null) {
          String orderName = order[0];
          bool desc = order.length == 1 ? false : order[1];
          query = query.orderBy(orderName, descending: desc);
        }
        if (start != null && start.isNotEmpty && start[0] != null) {
          dynamic startName = start[0];
          bool after = start.length == 1 ? false : start[1];
          query = after
              ? query.startAfter([startName])
              : query.startAt([startName]);
        }
        if (end != null && end.isNotEmpty && end[0] != null) {
          dynamic endName = end[0];
          bool before = end.length == 1 ? false : end[1];
          query = before ? query.endBefore([endName]) : query.endAt([endName]);
        }
        if (limit != null && limit.isNotEmpty && limit[0] != null) {
          int limitCount = limit[0];
          bool last = limit.length == 1 ? false : limit[1];
          query =
              last ? query.limitToLast(limitCount) : query.limit(limitCount);
        }
      }
    } else {
      query = getQueryPrevious(where, order, start, end, limit);
    }
    //print("query = ${query.parameters}");

    return query;
  }

  Query getQueryPrevious(List<dynamic>? where, List<dynamic>? order,
      List<dynamic>? start, List<dynamic>? end, List<dynamic>? limit) {
    Query query = this;
    if (where != null &&
        where.isNotEmpty &&
        where[0] != null &&
        where.length % 3 == 0) {
      int times = (where.length / 3).floor();
      for (int i = 0; i < times; i++) {
        final j = i * 3;
        String name = where[j + 0];
        String clause = where[j + 1];
        dynamic value = where[j + 2];

        //if (value != null) {
        if (clause == "==") {
          query = query.where(name, isEqualTo: value);
        }
        if (clause == "!=") {
          query = query.where(name, isNotEqualTo: value);
        }
        if (clause == "<") {
          query = query.where(name, isLessThan: value);
        }
        if (clause == ">") {
          query = query.where(name, isGreaterThan: value);
        }
        if (clause == "<=") {
          query = query.where(name, isLessThanOrEqualTo: value);
        }
        if (clause == ">=") {
          query = query.where(name, isGreaterThanOrEqualTo: value);
        }
        if (clause == "in") {
          query = query.where(name, whereIn: value);
        }
        if (clause == "notin") {
          query = query.where(name, whereNotIn: value);
        }
        if (clause == "contains") {
          query = query.where(name, arrayContains: value);
        }
        if (clause == "containsany") {
          query = query.where(name, arrayContainsAny: value);
        }
        if (clause == "is") {
          query = query.where(name, isNull: value);
        }
        //}
      }
    }
    if (order != null && order.isNotEmpty && order[0] != null) {
      String orderName = order[0];
      bool desc = order.length == 1 ? false : order[1];
      query = query.orderBy(orderName, descending: desc);
    }
    if (start != null && start.isNotEmpty && start[0] != null) {
      dynamic startName = start[0];
      bool after = start.length == 1 ? false : start[1];
      query =
          after ? query.startAfter([startName]) : query.startAt([startName]);
    }
    if (end != null && end.isNotEmpty && end[0] != null) {
      dynamic endName = end[0];
      bool before = end.length == 1 ? false : end[1];
      query = before ? query.endBefore([endName]) : query.endAt([endName]);
    }
    if (limit != null && limit.isNotEmpty && limit[0] != null) {
      int limitCount = limit[0];
      bool last = limit.length == 1 ? false : limit[1];
      query = last ? query.limitToLast(limitCount) : query.limit(limitCount);
    }
    return query;
  }
}
// extension ListQueryExtension on List<String> {
//   List<String> get toLoadMorePagination {
//     addAll([])
//   }
// }

extension ValueChangeExtension on ValueChange {
  bool get added => type == DocumentChangeType.added;
  bool get modified => type == DocumentChangeType.modified;
  bool get removed => type == DocumentChangeType.removed;
}
