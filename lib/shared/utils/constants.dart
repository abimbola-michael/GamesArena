import 'dart:io';

import 'package:flutter/foundation.dart';

const String CHANNEL_ID = "com.hms.gamesarena";
const String CHANNEL_NAME = "Games Arena";
const String CHANNEL_DESC = "This is a channel for Games Arena games";

const String batballGame = "Bat Ball";
const String xandoGame = "X and O";
const String whotGame = "Whot";
const String ludoGame = "Ludo";
const String draughtGame = "Draught";
const String chessGame = "Chess";
const String wordPuzzleGame = "Word Puzzle";

const String playedBatballGame = "playedBatball";
const String playedXandoGame = "playedXando";
const String playedWhotGame = "playedWhot";
const String playedLudoGame = "playedLudo";
const String playedDraughtGame = "playedDraught";
const String playedChessGame = "playedChess";
const String playedWordPuzzleGame = "playedWordPuzzle";

const List<String> allGames = [
  chessGame,
  draughtGame,
  whotGame,
  ludoGame,
  xandoGame,
  wordPuzzleGame
  //"Bat Ball",
  //"Ayo",
  //"Snooker"
  //"Jackpot",
  //"Scrabble"
];

const List<String> modes = [
  "Online",
  "Offline",
];

const int maxHintTime = 5;
const int maxGameTime = 15 * 60;
const int maxPlayerTime = 30;
const int maxChessDraughtTime = 10 * 60;
const int maxAdsTime = 60 * 5;
final adUnitId = kIsWeb
    ? ""
    : Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-3940256099942544/4411468910';
