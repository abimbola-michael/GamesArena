import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gamesarena/core/firebase/firestore_methods.dart';
import 'package:intl/intl.dart';

import '../../theme/colors.dart';
import '../models/list_change.dart';
import '../utils/utils.dart';
import '../widgets/app_bottom_sheet.dart';

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
  // bool get isPortrait =>
  //     MediaQuery.of(this).orientation == Orientation.portrait;
  bool get isPortrait => screenWidth < screenHeight;
  bool get isLandscape => screenWidth > screenHeight;

  double get minSize => screenWidth < screenHeight ? screenWidth : screenHeight;
  double get maxSize => screenWidth > screenHeight ? screenWidth : screenHeight;
  double get remainingSize => (maxSize - minSize) / 2;

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  // Size get screenSize => MediaQuery.of(this).size;

  double screenHeightPercentage(int percent) => screenHeight * percent / 100;
  double screenWidthPercentage(int percent) => screenWidth * percent / 100;
  double adaptiveTextSize(double size) => (size / 720) * screenHeight;

  ///new
  double get statusBarHeight => MediaQuery.of(this).padding.top;
  ThemeData get theme => Theme.of(this);
  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;
  double figmaHeight(double figmaHeight) =>
      figmaHeight * height / 812; //812 is the figma height
  double figmaWidth(double figmaWidth) =>
      figmaWidth * width / 375; //375 is the figma width
  double heightPercent(double percent, [double? subtract]) =>
      (height - (subtract ?? 0)) * percent / 100;
  double widthPercent(double percent, [double? subtract]) =>
      (width - (subtract ?? 0)) * percent / 100;
  Color? get iconColor => Theme.of(this).iconTheme.color;
  TextStyle? get bodyLarge => Theme.of(this).textTheme.bodyLarge;
  TextStyle? get bodyMedium => Theme.of(this).textTheme.bodyMedium;
  TextStyle? get bodySmall => Theme.of(this).textTheme.bodySmall;
  TextStyle? get headlineLarge => Theme.of(this).textTheme.headlineLarge;
  TextStyle? get headlineMedium => Theme.of(this).textTheme.headlineMedium;
  TextStyle? get headlineSmall => Theme.of(this).textTheme.headlineSmall;
  Color get bgColor => Theme.of(this).scaffoldBackgroundColor;
  Future pushTo(Widget page) =>
      Navigator.of(this).push(MaterialPageRoute(builder: (context) => page));
  Future pushNamedTo(String routeName, {Object? args}) =>
      Navigator.of(this).pushNamed(routeName, arguments: args);
  Future pushAndPop(Widget page, [result]) => Navigator.of(this)
      .pushReplacement(MaterialPageRoute(builder: (context) => page));
  Future pushReplacementNamed(String routeName,
          {Object? args, Object? result}) =>
      Navigator.of(this)
          .pushReplacementNamed(routeName, arguments: args, result: result);
  void pop([result]) => Navigator.of(this).pop(result);
  void popRoot([result]) => Navigator.of(this, rootNavigator: true).pop(result);

  void popUntil(String routeName) =>
      Navigator.of(this).popUntil(ModalRoute.withName(routeName));
  Future pushReplacementTo(Widget page, {Object? args}) => Navigator.of(this)
      .pushReplacement(MaterialPageRoute(builder: (context) => page),
          result: args);

  get args => ModalRoute.of(this)?.settings.arguments;
  Future showAppBottomSheet(WidgetBuilder builder) {
    return showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: this,
      builder: (context) => AppBottomSheet(child: builder(context)),
    );
  }

  Future showAppDialog(WidgetBuilder builder) {
    return showDialog(
      context: this,
      builder: builder,
    );
  }

  Future showAlertDialog(WidgetBuilder builder) {
    return showDialog(
      context: this,
      builder: builder,
    );
  }

  // Future showSnackBar(String message, [bool isError = true]) async {
  //   ScaffoldMessenger.of(this).showSnackBar(SnackBar(
  //       content: Text(
  //         message,
  //         style: bodySmall?.copyWith(color: white),
  //       ),
  //       backgroundColor: isError ? Colors.red : primaryColor));
  // }
}

extension DoubleExtensions on double {
  int get toDegrees => (this * (180.0 / 3.14159265)).toInt();
  double percentValue(int percent) => this * percent / 100;
}

extension IntExtensions on int {
  int get minToSec => this * 60;

  String toDuration() {
    String duration = "";
    final hours = this ~/ 3600;
    final minutes = this % 3600 ~/ 60;
    final seconds = this % 60;
    if (this < 60) {
      duration = "$seconds secs";
    } else if (this < 3600) {
      duration = "$minutes:${seconds.toDigitsOf(2)} mins";
    } else {
      duration =
          "$hours:${minutes.toDigitsOf(2)}:${seconds.toDigitsOf(2)} hours";
    }
    return duration;
  }

  String toDurationString([bool isTimer = true]) {
    String duration = "";
    final hours = this ~/ 3600;
    final minutes = this % 3600 ~/ 60;
    final seconds = this % 60;
    if (this < 60) {
      duration =
          isTimer ? "00:${seconds.toDigitsOf(2)}" : seconds.toDigitsOf(2);
    } else if (this <= 600) {
      duration =
          "${minutes.toDigitsOf(isTimer ? 2 : 1)}:${seconds.toDigitsOf(2)}";
    } else if (this > 600 && this < 3600) {
      duration =
          "${minutes.toDigitsOf(isTimer ? 2 : 1)}:${seconds.toDigitsOf(2)}";
    } else {
      duration =
          "${hours.toDigitsOf(2)}:${minutes.toDigitsOf(2)}:${seconds.toDigitsOf(2)}";
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
  String timeAgo({bool numericDates = true}) {
    final date2 = DateTime.now();
    final difference = date2.difference(this);
    if ((difference.inDays / 7).floor() >= 1) {
      return (numericDates) ? '1 week ago' : 'Last week';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 1) {
      return (numericDates) ? '1 day ago' : 'Yesterday';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours >= 1) {
      return (numericDates) ? '1 hour ago' : 'An hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inMinutes >= 1) {
      return (numericDates) ? '1 minute ago' : 'A minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }

  bool showDate(DateTime prevDate) {
    return (day - prevDate.day) > 0;
  }

  String dateRange() {
    final difference = DateTime.now().day - day;
    if (difference <= 0) {
      return "Today";
    } else if (difference == 1) {
      return "Yesterday";
    } else {
      return date;
    }
  }

  String timeRange() {
    final difference = DateTime.now().day - day;
    if (difference == 0) {
      return time;
    } else if (difference == 1) {
      return "Yesterday";
    } else {
      return date;
    }
  }
}

extension StringExtensions on String {
  String? toValidNumber(String? dialCode) {
    if (trim().length < 10 ||
        (RegExp(r"[^0-9]").hasMatch(trim().firstChar!) &&
            trim().firstChar != "+")) {
      return null;
    }
    dialCode ??= "+1";
    bool startsWithZero = trim().startsWith("0");
    String refinedNumber = replaceAll(RegExp(r"\D"), "")
        .replaceAll(" ", "")
        .replaceAll("+", "")
        .trim();
    return startsWithZero
        ? "$dialCode${refinedNumber.substring(1)}"
        : "+$refinedNumber";
  }

  String get onlyErrorMessage {
    if (contains("[") && contains("]")) {
      return substring(indexOf("]") + 1).trim();
    }
    return this;
  }

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
      if (!alphanumeric.contains(char) &&
          (exceptions == null || !exceptions.contains(char))) {
        return true;
      }
    }
    return false;
  }

  bool exceededSymbolCount(List<String> symbols) {
    bool found = false;
    for (int i = 0; i < length; i++) {
      final char = this[i];
      if (symbols.contains(char)) {
        if (!found) {
          found = true;
        } else {
          return true;
        }
      }
    }
    return false;
  }

  // bool hasNumberInternally() {
  //   bool foundNumber = false;
  //   for (int i = 0; i < length; i++) {
  //     final char = this[i];
  //     if (foundNumber) {
  //       if (alphabets.contains(this[0]) || capsalphabets.contains(this[0])) {
  //         return true;
  //       }
  //     }
  //     if (numbers.contains(char)) {
  //       if (!foundNumber) {
  //         foundNumber = true;
  //       }
  //     }
  //   }
  //   return false;
  // }

  bool startWithLetter() {
    return length == 0
        ? false
        : (alphabets.contains(this[0]) || capsalphabets.contains(this[0]));
  }

  bool endsWithLetterOrNumber() {
    return length == 0 ? false : alphanumeric.contains(this[length - 1]);
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
    final emailPattern = RegExp("^[_A-Za-z0-9-\\+]+(\\.[_A-Za-z0-9-]+)*@"
        "[A-Za-z0-9-]+(\\.[A-Za-z0-9]+)*(\\.[A-Za-z]{2,})\$");
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

  String get toJpg => "assets/images/png/$this.jpg";
  String get toPng => "assets/images/png/$this.png";
  String get toSvg => "assets/images/svg/$this.svg";
  String get toImage => "assets/images/$this";

  DateTime get toDateTime => DateTime.fromMillisecondsSinceEpoch(toInt);
  String lastChars(int n) => substring(length - n);

  String get toValidTime {
    DateTime parsedTime = DateFormat('HH:mm:ss').parse(this);
    String formattedTime = DateFormat('h:mma').format(parsedTime).toLowerCase();
    return formattedTime;
  }

  double get toDouble {
    if (double.tryParse(this) != null) {
      return double.parse(this);
    } else if (int.tryParse(this) != null) {
      return int.parse(this).toDouble();
    } else {
      return 0;
    }
  }

  int get toInt {
    if (int.tryParse(this) != null) {
      return int.parse(this);
    } else if (double.tryParse(this) != null) {
      return double.parse(this).toInt();
    } else {
      return 0;
    }
  }

  Color get toColor {
    String string = this;
    if (startsWith("rgb")) {
      string = toHex;
    }
    return Color(
        "0xFF${string.isEmpty ? "" : string.substring(string.indexOf("#") + 1)}"
            .toInt);
  }

  String get toHex {
    final openIndex = indexOf("(");
    final closeIndex = indexOf(")");
    if (openIndex == -1 || closeIndex == -1) return "";
    final detailsString = substring(openIndex + 1, closeIndex);
    final details = detailsString.split(", ");
    int r = details[0].toInt;
    int g = details[1].toInt;
    int b = details[2].toInt;
    double opacity = details.length < 4 ? 0 : details[3].toDouble;
    int opacityHex = (opacity * 255).round();
    return '#${opacityHex.toRadixString(16).padLeft(2, '0')}${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }
}

extension StringMapExtension<T> on Map<String, T> {
  List<T> toList() {
    List<T> list = [];
    for (int i = 0; i < length; i++) {
      final value = this["$i"];
      if (value != null) list.add(value);
    }
    return list;
  }
}

extension MapExtension<T, U> on Map<T, U> {
  Map<T, U> getChangedProperties(Map<T, U> newMap) {
    Map<T, U> resultMap = {};
    for (var entry in newMap.entries) {
      if (this[entry.key] != entry.value) {
        resultMap[entry.key] = entry.value;
      }
    }
    return resultMap;
  }
}

// extension ListNullableExtensions<T, U> on List<T?> {
//   T? firstWhereNullable(bool Function(T? t) callback, [int start = 0]) {
//     final index = indexWhere(callback, start);
//     if (index != -1) {
//       return this[index];
//     }
//     return null;
//   }
// }

extension ListExtensions<T, U> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
  T? get firstOrNull => isEmpty ? null : first;
  T? valueOrNull(int index) => isEmpty ? null : this[index];

  T? firstWhereNullable(bool Function(T t) callback, [int start = 0]) {
    final index = indexWhere(callback, start);
    if (index != -1) {
      return this[index];
    }
    return null;
  }

  bool equals(List<T> other) {
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if (this[i] != other[i]) {
        return false;
      }
    }
    return true;
  }

  String toStringWithCommaandAnd(String Function(T t) callback,
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
        ? callback(j)?.compareTo(callback(i))
        : callback(i)?.compareTo(callback(j)));
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
      newList[i] = this[indices[i] >= length ? indices[i] - 1 : indices[i]];
    }
    return newList;
  }

  List<T> sortWithStringList(
      List<String> order, String Function(T value) callback) {
    List<T> newList = [];
    if (order.isEmpty || order.length != length) {
      return this;
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

  Map<String, T> toMap() {
    Map<String, T> listmap = {};
    for (int i = 0; i < length; i++) {
      listmap["$i"] = this[i];
    }
    return listmap;
  }

  Map<String, T> toStringMap(String Function(T t) callback) {
    Map<String, T> listmap = {};
    for (int i = 0; i < length; i++) {
      listmap[callback(this[i])] = this[i];
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
