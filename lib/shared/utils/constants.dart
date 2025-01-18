import 'dart:io';

import 'package:flutter/foundation.dart';

const String CHANNEL_ID = "com.hms.gamesarena";
const String CHANNEL_NAME = "Games Arena";
const String CHANNEL_DESC = "This is a channel for Games Arena games";

//board
const String batballGame = "Bat Ball";
const String xandoGame = "X and O";
const String ludoGame = "Ludo";
const String draughtGame = "Draught";
const String chessGame = "Chess";

//card
const String whotGame = "Whot";

//puzzle
const String wordPuzzleGame = "Word Puzzle";

//quiz
const String quizGame = "Quiz";

const String brainTeaserQuizGame = "Brain Teaser";
const String bibleQuizGame = "Bible Quiz";
const String quranQuizGame = "Quran Quiz";
const String englishQuizGame = "English Quiz";
const String mathsQuizGame = "Maths Quiz";
const String biologyQuizGame = "Biology Quiz";
const String physisQuizGame = "Physis Quiz";
const String chemistryQuizGame = "Chemistry Quiz";
const String scienceQuizGame = "Science Quiz";
const String artQuizGame = "Art Quiz";
const String lawQuizGame = "Law Quiz";
const String medicalQuizGame = "Medical Quiz";
const String engineeringQuizGame = "Engineering Quiz";

const String englishLiteratureQuizGame = "English Literature Quiz";
const String verbalAptQuizGame = "Verbal Aptitude Quiz";
const String quantitativeAptQuizGame = "Quantitative Aptitude Quiz";
const String vocationalAptQuizGame = "Vocational Aptitude Quiz";
const String generalKnowledgeQuizGame = "General Knowledge Quiz";
const String currentAffairsQuizGame = "Current Affairs Quiz";

const String techQuizGame = "Tech Quiz";

const String yourTopicQuizGame = "Your Topic Quiz";

const List<String> allQuizGames = [
  brainTeaserQuizGame,
  bibleQuizGame,
  quranQuizGame,
  englishQuizGame,
  mathsQuizGame,
  biologyQuizGame,
  physisQuizGame,
  chemistryQuizGame,
  scienceQuizGame,
  artQuizGame,
  lawQuizGame,
  medicalQuizGame,
  engineeringQuizGame,
  englishLiteratureQuizGame,
  verbalAptQuizGame,
  quantitativeAptQuizGame,
  vocationalAptQuizGame,
  techQuizGame,
  generalKnowledgeQuizGame,
  currentAffairsQuizGame,
  yourTopicQuizGame
];

const List<String> allBoardGames = [
  chessGame,
  draughtGame,
  ludoGame,
  xandoGame
];
const List<String> allCardGames = [whotGame];
const List<String> allPuzzleGames = [wordPuzzleGame];

const List<String> allGames = [
  ...allBoardGames,
  ...allCardGames,
  ...allPuzzleGames,
  quizGame,
  //"Bat Ball",
  //"Ayo",
  //"Snooker"
  //"Jackpot",
  //"Scrabble"
];
const List<String> allGameCategories = ["Board", "Card", "Puzzle", "Quiz"];
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
