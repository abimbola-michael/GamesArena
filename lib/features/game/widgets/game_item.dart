import 'package:flutter/material.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:gamesarena/shared/utils/utils.dart';

import '../../../shared/utils/constants.dart';

class GameItemWidget extends StatelessWidget {
  final String game;
  final double width;
  final VoidCallback onPressed;
  const GameItemWidget(
      {super.key,
      required this.game,
      required this.width,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      //height: width + 24,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.topLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: width - 16,
            height: width - 16,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Card(
                  semanticContainer: true,
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  color: lightestTint,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Image.asset(getImageAsset(), fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            game,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  String getImageAsset() {
    String asset = "batball.jpeg";
    if (game == batballGame) {
      asset = "batball.jpeg";
    } else if (game == whotGame) {
      asset = "whot.jpeg";
    } else if (game == ludoGame) {
      asset = "ludo.jpeg";
    } else if (game == draughtGame) {
      asset = "draught.jpeg";
    } else if (game == chessGame) {
      asset = "chess.jpeg";
    } else if (game == xandoGame) {
      asset = "xando.jpeg";
    } else if (game == wordPuzzleGame) {
      asset = "word_puzzle.jpg";
    } else if (game == artQuizGame) {
      asset = "art_quiz.jpg";
    } else if (game == bibleQuizGame) {
      asset = "bible_quiz.png";
    } else if (game == brainTeaserQuizGame) {
      asset = "brain_teaser.jpg";
    } else if (game == chemistryQuizGame) {
      asset = "chemistry_quiz.jpg";
    } else if (game == currentAffairsQuizGame) {
      asset = "current_affairs_quiz.png";
    } else if (game == engineeringQuizGame) {
      asset = "engineering_quiz.jpg";
    } else if (game == englishLiteratureQuizGame) {
      asset = "english_literature_quiz.jpg";
    } else if (game == englishQuizGame) {
      asset = "english_quiz.png";
    } else if (game == generalKnowledgeQuizGame) {
      asset = "general_knowledge_quiz.jpg";
    } else if (game == mathsQuizGame) {
      asset = "math_quiz.jpg";
    } else if (game == medicalQuizGame) {
      asset = "medical_quiz.jpg";
    } else if (game == physisQuizGame) {
      asset = "physics_quiz.jpg";
    } else if (game == quantitativeAptQuizGame) {
      asset = "quantitative_aptitude_quiz.jpg";
    } else if (game == quranQuizGame) {
      asset = "quran_quiz.jpg";
    } else if (game == scienceQuizGame) {
      asset = "science_quiz.jpg";
    } else if (game == techQuizGame) {
      asset = "tech_quiz.jpg";
    } else if (game == verbalAptQuizGame) {
      asset = "verbal_aptitude_quiz.jpg";
    } else if (game == vocationalAptQuizGame) {
      asset = "vocational_aptitude_quiz.jpg";
    } else if (game == yourTopicQuizGame) {
      asset = "your_topic_quiz.jpg";
    } else if (game == biologyQuizGame) {
      asset = "biology_quiz.jpg";
    } else if (game == lawQuizGame) {
      asset = "law_quiz.jpg";
    }
    return asset.toImage;
  }
}
