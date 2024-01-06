import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../utils/utils.dart';

extension ContextExtensions on BuildContext {
  bool get isDarkMode {
    return MediaQuery.of(this).platformBrightness == Brightness.dark;
  }

  bool get isMobile => MediaQuery.of(this).size.width < 730;
  bool get isTablet {
    var width = MediaQuery.of(this).size.width;
    return width < 1190 && width >= 730;
  }

  bool get isWeb => MediaQuery.of(this).size.width >= 1190;
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  // Size get screenSize => MediaQuery.of(this).size;
  double get statusBarHeight => MediaQuery.of(this).padding.top;

  double screenHeightPercentage(int percent) => screenHeight * percent / 100;
  double screenWidthPercentage(int percent) => screenWidth * percent / 100;
}

extension DoubleExtensions on double {
  int get toDegrees => (this * (180.0 / 3.14159265)).toInt();
  double percentValue(int percent) => this * percent / 100;
}

extension IntExtensions on int {
  String get toDurationString {
    String duration = "";
    final hours = this ~/ 3600;
    final minutes = this % 3600 ~/ 60;
    final seconds = this % 60;
    if (this < 60) {
      duration = "00:${seconds.toDigitsOf(2)}";
    } else if (this <= 600) {
      duration = "${minutes.toDigitsOf(2)}:${seconds.toDigitsOf(2)}";
    } else if (this > 600 && this < 3600) {
      duration = "${minutes.toDigitsOf(2)}:${seconds.toDigitsOf(2)}";
    } else {
      duration = "$hours:${minutes.toDigitsOf(2)}:${seconds.toDigitsOf(2)}";
    }
    return duration;
  }

  String toDigitsOf(int value) {
    String intString = "";
    if (toString().length < value) {
      int numberOfZerosToAdd = value - toString().length;
      if (value > numberOfZerosToAdd) {
        for (int i = 0; i < numberOfZerosToAdd; i++) {
          intString += "0";
        }
      }
      intString += "$this";
      return intString;
    } else {
      return toString();
    }
  }
}

extension DateTimeExtensions on DateTime {
  String get time => DateFormat.jm().format(this);
  String get date => DateFormat.yMMMd().format(this);
  String get hour => DateFormat("hh").format(this);
}

extension StringExtensions on String {
  String? get lastChar => length > 0 ? this[length - 1] : null;
  String? get firstChar => length > 0 ? this[0] : null;

  String get capitalize =>
      isNotEmpty ? substring(0, 1).toUpperCase() + substring(1) : "";
  bool get endsWithSymbol =>
      lastChar == null ? false : !alphanumeric.contains(lastChar);
  bool get endsWithNumber =>
      lastChar == null ? false : numbers.contains(lastChar);

  bool get startsWithSymbol =>
      firstChar == null ? false : !alphanumeric.contains(firstChar);
  bool get startsWithNumber =>
      firstChar == null ? false : numbers.contains(firstChar);

  bool containsSymbol([List<String>? exceptions]) {
    for (int i = 0; i < length; i++) {
      final char = this[i];
      return (exceptions == null || (!exceptions.contains(char))) &&
          !alphanumeric.contains(char);
    }
    return false;
  }

  bool isOnlyNumber() {
    for (int i = 0; i < length; i++) {
      final char = this[i];
      if (!numbers.contains(char)) {
        return false;
      }
    }
    return true;
  }

  bool isValidEmail() {
    final emailPattern = RegExp("^[_A-Za-z0-9-\\+]+(\\.[_A-Za-z0-9-]+)*@" "[A-Za-z0-9-]+(\\.[A-Za-z0-9]+)*(\\.[A-Za-z]{2,})\$");
    return emailPattern.hasMatch(this);
  }

  bool greaterThan(String second) {
    if (length == 0 || second.isEmpty) return false;
    List<String> alphabetsList = alphabets;
    String firstChar = "";
    String secondChar = "";
    for (int i = 0; i < second.length; i++) {
      firstChar = this[i];
      secondChar = second[i];
      if (firstChar != secondChar) {
        return alphabetsList.indexOf(firstChar) >
            alphabetsList.indexOf(secondChar);
      }
    }
    return false;
  }

  bool lessThan(String second) {
    if (length == 0 || second.isEmpty) return false;
    List<String> alphabetsList = alphabets;
    String firstChar = "";
    String secondChar = "";
    for (int i = 0; i < second.length; i++) {
      firstChar = this[i];
      secondChar = second[i];
      if (firstChar != secondChar) {
        return alphabetsList.indexOf(firstChar) <
            alphabetsList.indexOf(secondChar);
      }
    }
    return false;
  }

  DateTime get datetime => DateTime.fromMillisecondsSinceEpoch(int.parse(this));
  String get time => DateFormat.jm().format(datetime);
  String get date => DateFormat.yMMMd().format(datetime);
  String get dateandtime => "$date $time";
  String get dateortime {
    final now = DateTime.now();
    //final date = datetime;
    return (now.hour - datetime.hour) > 24 ? date : time;
  }

  String get toYesterdayOrTodayOrTime {
    final now = DateTime.now();
    return (now.hour - datetime.hour) >= 48
        ? date
        : (now.hour - datetime.hour) >= 24
            ? "Yesterday"
            : "Today";
  }

  List<String> get fromCommaSeperatedString => split(",");

  int get toMilisecs => datetime.millisecondsSinceEpoch;
  String dateString({String? seperator = " ", bool? monthInWords}) {
    DateTime dt = datetime;
    return dt.year.toString() +
        seperator! +
        dt.month.toString() +
        seperator +
        dt.day.toString();
  }
}

extension ListExtensions<T, U> on List<T> {
  bool equals(List<T> other) {
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if (this[i] != other[i]) {
        return false;
      }
    }
    return true;
  }

  String toStringWithCommaandAnd(String Function(T) callback,
      [String addition = ""]) {
    String finalString = "";
    for (int i = 0; i < length; i++) {
      final string = addition + callback(this[i]);
      if (i != 0) {
        if (i != length - 1 && length > 2) {
          finalString += ", ";
        } else if (i == length - 1) {
          finalString += " and ";
        }
      }
      finalString += string;
    }
    return finalString;
  }

  void sortList(dynamic Function(T) callback, bool dsc) => sort((i, j) => dsc
      ? callback(j).compareTo(callback(i))
      : callback(i).compareTo(callback(j)));

  List<T> sortedList(dynamic Function(T) callback, bool dsc) {
    if (isEmpty) return [];
    List<T> list = [];
    list.addAll(this);
    list.sort((i, j) => dsc
        ? callback(j).compareTo(callback(i))
        : callback(i).compareTo(callback(j)));
    return list;
  }

  List<T> arrangeWithIntList(List<int> order) {
    List<T> newList = [];
    if (order.isEmpty || order.length != length) {
      return [];
    }
    for (int i = 0; i < order.length; i++) {
      final index = order[i];
      final t = this[index];
      newList.add(t);
    }
    return newList;
  }

  List<T> arrangeWithStringList(List<String> order) {
    List<T> newList = [];
    if (order.isEmpty || order.length != length) {
      return [];
    }
    for (int i = 0; i < order.length; i++) {
      final index = int.tryParse(order[i]);
      if (index != null) {
        final t = this[index];
        newList.add(t);
      }
    }
    return newList;
  }

  List<T> updateWithIntList(List<int> indices) {
    List<T> newList = [];
    if (indices.isEmpty || indices.length != length) {
      return [];
    }
    newList.addAll(this);
    for (int i = 0; i < length; i++) {
      newList[i] = this[indices[i]];
    }
    return newList;
  }

  List<T> sortWithStringList(
      List<String> order, String Function(T value) callback) {
    List<T> newList = [];
    if (order.isEmpty || order.length != length) {
      return [];
    }
    for (int i = 0; i < order.length; i++) {
      final index = indexWhere((element) => callback(element) == order[i]);
      if (index != -1) {
        newList.add(this[index]);
      }
    }
    return newList;
  }

  String toListString() {
    String string = "[";
    for (int i = 0; i < length; i++) {
      final t = this[i];
      string += "\"";
      string += t.toString();
      string += "\"";
      if (i != length - 1) {
        string += ",";
      }
    }
    string += "]";
    return string;
  }

  Map<int, T> toMap() {
    Map<int, T> listmap = {};
    for (int i = 0; i < length; i++) {
      listmap[i] = this[i];
    }
    return listmap;
  }

  T? get second => length > 1 ? this[1] : null;
  T? get third => length > 2 ? this[2] : null;
  T? get fourth => length > 3 ? this[3] : null;

  Map<U, List<T>> groupList(U Function(T) callback) {
    Map<U, List<T>> map = {};
    for (T t in this) {
      final value = map[callback(t)];
      if (value != null) {
        value.add(t);
        map[callback(t)] = value;
      } else {
        map[callback(t)] = [t];
      }
    }
    return map;
  }

  List<List<T>> groupListToList(U Function(T) callback) {
    Map<U, List<T>> map = {};
    List<List<T>> list = [];
    for (T t in this) {
      final value = map[callback(t)];
      if (value != null) {
        value.add(t);
        map[callback(t)] = value;
      } else {
        map[callback(t)] = [t];
      }
    }
    for (var entry in map.entries) {
      list.add(entry.value);
    }
    return list;
  }
}

int fibonnacci(int value) {
  if (value <= 1) return value;
  return fibonnacci(value - 1) + fibonnacci(value - 2);
}

extension DatabaseReferenceExtension<T> on DatabaseReference {
  Query getQuery(List<dynamic>? where, List<dynamic>? order,
      List<dynamic>? start, List<dynamic>? end, List<dynamic>? limit) {
    Query query = this;
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
