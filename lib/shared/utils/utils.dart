import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';

import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:flutter/material.dart';

import 'dart:io';
import 'package:gamesarena/main.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/game/models/match_outcome.dart';
import '../../features/game/models/player.dart';
import '../../features/game/services.dart';

import '../../features/user/models/user.dart';
import '../extensions/special_context_extensions.dart';

// String get myId => currentUserId;
String get myId => auth.FirebaseAuth.instance.currentUser?.uid ?? "";

bool get isAndroidAndIos => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
bool get isWindows => !kIsWeb && Platform.isWindows;

// bool get darkMode =>
//     SchedulerBinding.instance.window.platformBrightness == Brightness.dark;
double statusBarHeight = window.padding.top / window.devicePixelRatio;
String get timeNow => DateTime.now().millisecondsSinceEpoch.toString();
bool get darkMode => themeValue == 1;
List<String> capsalphabets = [
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "W",
  "X",
  "Y",
  "Z"
];
List<String> alphabets = [
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z",
];
List<String> numbers = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
List<String> alphanumeric = [...alphabets, ...capsalphabets, ...numbers];

Future launchUrlIfCan(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri);
  }
}

List<String> getRandomIndex(int size) {
  List<String> indices = List.generate(size, (index) => "$index");
  for (int i = 0; i < 10; i++) {
    indices.shuffle();
  }
  return indices;
}

List<int> getPlayersToRemove(List<User?> users, List<Player> players) {
  List<int> indices = [];
  for (int i = 0; i < users.length; i++) {
    final user = users[i];
    final index = players.indexWhere((element) => element.id == user?.user_id);
    if (index == -1) {
      indices.add(i);
    }
  }
  return indices;
}

MatchOutcome getMatchOutcome(List<int> playersScores, List<String> playerIds) {
  Map<int, List<int>> resultMap = {};
  for (int i = 0; i < playersScores.length; i++) {
    final score = playersScores[i];
    if (resultMap[score] != null) {
      resultMap[score]!.add(i);
    } else {
      resultMap[score] = [i];
    }
  }
  final scores = resultMap.keys.toList();
  final highestScore = scores.sortedList((value) => value, false).last;
  final players = resultMap[highestScore]!;
  final winners = players.map((index) => playerIds[index]).toList();
  final others =
      playerIds.where((player) => !winners.contains(player)).toList();
  final othersIndices =
      others.map((player) => playerIds.indexOf(player)).toList();
  if (scores.length == 1) {
    return MatchOutcome(
        outcome: "draw",
        winners: [],
        winnersIndices: [],
        others: playerIds,
        othersIndices: players);
  } else {
    return MatchOutcome(
        outcome: "win",
        winners: winners,
        winnersIndices: players,
        others: others,
        othersIndices: othersIndices);
  }
}

List<String> getPlayersNames(List<Player> players,
    {List<User?>? users, int playersSize = 2}) {
  final usernames = (users ?? []).isNotEmpty && players.isNotEmpty
      ? players
          .map((player) =>
              users!
                  .firstWhereNullable((user) => user?.user_id == player.id)
                  ?.username ??
              "")
          .toList()
      : List.generate(playersSize, (index) => "Player ${index + 1}");
  return usernames;
}

String getMatchOutcomeMessageFromScores(
    List<int> playersScores, List<String> players,
    {List<User?>? users}) {
  final playerIds = (users ?? []).isNotEmpty && players.isNotEmpty
      ? players
      : List.generate(playersScores.length, (index) => "$index");
  final usernames = (users ?? []).isNotEmpty && players.isNotEmpty
      ? players
          .map((player) =>
              users!
                  .firstWhereNullable((user) => user?.user_id == player)
                  ?.username ??
              "")
          .toList()
      : List.generate(playersScores.length, (index) => "Player ${index + 1}");
  final matchOutcome = getMatchOutcome(playersScores, playerIds);
  if (matchOutcome.outcome == "draw") {
    return "It's a draw";
  } else {
    if (matchOutcome.winnersIndices.length == 1) {
      return "${usernames[matchOutcome.winnersIndices.first]} won";
    } else {
      return "It's a tie between ${matchOutcome.winnersIndices.map((index) => usernames[index]).toList().toStringWithCommaandAnd((t) => t)}";
    }
  }
}

String getMatchOutcomeMessageFromWinners(
    List<int>? winners, List<String> players,
    {List<User?>? users}) {
  if (winners == null) return "Incomplete Round";
  if (winners.isEmpty) return "It's a draw";

  final winnersUsernames = (users ?? []).isNotEmpty
      ? winners
          .map((index) =>
              users!
                  .firstWhereNullable((user) => user?.user_id == players[index])
                  ?.username ??
              "")
          .toList()
      : List.generate(
          winners.length, (index) => "Player ${winners[index] + 1}");
  if (winnersUsernames.length == 1) {
    return "${winnersUsernames.first} won";
  } else {
    return "It's a tie between ${winnersUsernames.toStringWithCommaandAnd((t) => t)}";
  }
}

String getWinnerMessage(List<int> playersScores, List<User?>? users) {
  String message = "";
  Map<int, List<int>> resultMap = {};
  for (int i = 0; i < playersScores.length; i++) {
    final score = playersScores[i];
    if (resultMap[score] != null) {
      resultMap[score]!.add(i);
    } else {
      resultMap[score] = [i];
    }
  }
  final scores = resultMap.keys.toList();
  final highestScore = scores.sortedList((value) => value, false).last;
  final players = resultMap[highestScore]!;
  if (players.length > 1) {
    if (scores.length == 1) {
      message = "It's a draw";
    } else {
      String tiePlayers = "";
      if ((users ?? []).isNotEmpty) {
        tiePlayers =
            users!.toStringWithCommaandAnd((user) => user?.username ?? "");
      } else {
        tiePlayers = resultMap[highestScore]!
            .toStringWithCommaandAnd((value) => "${value + 1}", "Player ");
      }
      message = "It's a tie between $tiePlayers";
    }
  } else {
    final player = players.first;
    message = (users ?? []).isNotEmpty
        ? "${users![player]?.username} won"
        : "Player ${player + 1} won";
  }

  return message;
}

String getActionMessage(List<Player> prevPlaying, List<Player> newPlaying,
    List<User> users, String game) {
  prevPlaying.sortList((value) => value.order, false);
  newPlaying.sortList((value) => value.order, false);
  List<Player> players = newPlaying, toPlaying = prevPlaying;
  String action = "";
  if (newPlaying.length > prevPlaying.length) {
    action = "joined";
    players = newPlaying;
    toPlaying = prevPlaying;
  } else if (newPlaying.length < prevPlaying.length) {
    action = "left";
    players = prevPlaying;
    toPlaying = newPlaying;
  }
  for (int i = 0; i < players.length; i++) {
    final value = players[i];
    final toValue = toPlaying[i];
    final username = users.isEmpty
        ? ""
        : users.firstWhere((element) => element.user_id == value.id).username;
    if (value.id != toValue.id) {
      return "$username $action";
    }
    if (value.action != toValue.action) {
      return "$username ${getActionString(value.action)}";
    }
  }
  return "";
}

String getAction(List<Player> players) {
  if (players.isEmpty) return "pause";
  if (players.length == 1) return players.first.action ?? "pause";

  String action = players.first.action ?? "pause";
  int playersCount = 1;

  if (action == "ad") {
    return "pause";
  }

  for (int i = 1; i < players.length; i++) {
    final player = players[i];
    final playerAction = player.action ?? "pause";

    if (playerAction == "ad") {
      return "pause";
    }

    if (playerAction == "close" ||
        playerAction == "unclose" ||
        playerAction == "concede" ||
        playerAction == "leave") {
      continue;
    }

    playersCount++;

    if (action != playerAction) {
      return "pause";
    }
  }
  final outputAction = playersCount == 1 ? "pause" : action;
  // print("outputAction = $outputAction");

  // print("players = $players");
  return outputAction;
}

Player? getMyPlayer(List<Player> players) {
  for (int i = 0; i < players.length; i++) {
    final player = players[i];
    if (player.id == myId) {
      return player;
    }
  }
  return null;
}

String? getMyCallMode(List<Player> players) {
  for (int i = 0; i < players.length; i++) {
    final player = players[i];
    if (player.id == myId) {
      return player.callMode;
    }
  }
  return null;
}

String? getCallMode(List<Player> players) {
  String? callMode;
  for (int i = 0; i < players.length; i++) {
    final player = players[i];

    if (callMode == null && player.callMode != null) {
      callMode = player.callMode;
    } else {
      if (callMode != player.callMode) {
        return "";
      }
    }
  }
  return callMode;
}

String getChangedGame(List<Player> players) {
  String game = "";
  for (int i = 0; i < players.length; i++) {
    final player = players[i];
    if (game == "") {
      game = player.game ?? "";
    } else {
      if (game != player.game) {
        return "";
      }
    }
  }
  return game;
}

String getActionString(String? action) {
  return action == null
      ? ""
      : action == "start"
          ? "started"
          : action == "restart"
              ? "restarted"
              : action == "pause"
                  ? "paused"
                  : action;
}

Future updateAction(
    BuildContext context,
    List<Player> players,
    List<User?> users,
    String gameId,
    String matchId,
    String action,
    String game) async {
  final myPlaying = players.firstWhere((element) => element.id == myId);
  final myAction = myPlaying.action;
  if (myAction != action) {
    // if (action == "restart") {
    //   await restartGame(game, gameId, matchId, players, id, duration);
    // } else if (action == "start") {
    //   await startGame(game, gameId, matchId, players, id, started);
    // }
    await updatePlayerAction(gameId, action, game);
  }
  final othersPlaying = players.where((element) => element.id != myId).toList();
  final othersWithDiffAction = othersPlaying
      .where((element) => element.id != myId && element.action != myAction)
      .toList();

  if (othersWithDiffAction.isNotEmpty) {
    List<User> waitingUsers = [];
    for (int i = 0; i < othersWithDiffAction.length; i++) {
      final players = othersWithDiffAction[i];
      final user = users.isEmpty
          ? null
          : users.firstWhere(
              (element) => element != null && element.user_id == players.id);
      if (user != null) {
        waitingUsers.add(user);
      }
    }
    showToast(
        "Waiting for ${waitingUsers.toStringWithCommaandAnd((user) => user.username)} to also $action");
  }
}

List<int> convertToGrid(int pos, int gridSize) {
  return [pos % gridSize, pos ~/ gridSize];
}

int convertToPosition(List<int> grids, int gridSize) {
  return grids[0] + (grids[1] * gridSize);
}

int nextIndex(int playersSize, int index) {
  return index == playersSize - 1 ? 0 : index + 1;
}

int prevIndex(int playersSize, int index) {
  return index == 0 ? playersSize - 1 : index - 1;
}

bool isValidEmail(String email) {
  // Regular expression for validating an email address
  // final pattern = RegExp("^[_A-Za-z0-9-\\+]+(\\.[_A-Za-z0-9-]+)*@" "[A-Za-z0-9-]+(\\.[A-Za-z0-9]+)*(\\.[A-Za-z]{2,})\$");

  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

bool isValidPhoneNumber(String phoneNumber, [int limit = 10]) {
  if (phoneNumber.length < limit) return false;
  // Regular expression for validating a generic phone number
  // final RegExp phoneRegex =
  //     RegExp(r'^[0-9]{10}$'); // Assuming 10-digit phone number format
  final RegExp phoneRegex = RegExp(r'^[0-9]'); //
  return phoneRegex.hasMatch(phoneNumber);
}

bool isValidUserName(String name) {
  // Check if the name is not empty
  if (name.isEmpty) {
    return false;
  }

  // Check if the name contains only alphabetic characters, spaces, or hyphens
  // final RegExp nameRegex = RegExp(r'^[a-zA-Z0-9\_]+$');
  final RegExp usernameRegex = RegExp(r'^[a-z0-9\_]+$');

  return usernameRegex.hasMatch(name);
}

bool isValidName(String name) {
  // Check if the name is not empty
  if (name.isEmpty) {
    return false;
  }

  // Check if the name contains only alphabetic characters, spaces, or hyphens
  final RegExp nameRegex = RegExp(r'^[a-zA-Z0-9\- ]+$');
  return nameRegex.hasMatch(name);
}

bool isValidPassword(String password) {
  // Check if password is at least 8 characters long
  if (password.length < 6) {
    return false;
  }

  // Check if password contains at least one uppercase letter
  if (!password.contains(RegExp(r'[A-Z]'))) {
    return false;
  }

  // Check if password contains at least one lowercase letter
  if (!password.contains(RegExp(r'[a-z]'))) {
    return false;
  }

  // Check if password contains at least one digit
  if (!password.contains(RegExp(r'[0-9]'))) {
    return false;
  }

  // Check if password contains at least one special character
  if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    return false;
  }

  // If all criteria are met, return true
  return true;
}

bool hasValidLength(String input, int minLength, int maxLength) {
  final length = input.length;
  return length >= minLength && length <= maxLength;
}

Future<void> clearAllBoxes(List<String> boxNames) async {
  // Ensure that Hive is initialized
  //await Hive.initFlutter();

  // Get a list of all open box names

  // Loop through each box name and delete its contents
  for (String boxName in boxNames) {
    var box = Hive.box(boxName);
    await box.clear(); // Clears all data in the box
  }
}
