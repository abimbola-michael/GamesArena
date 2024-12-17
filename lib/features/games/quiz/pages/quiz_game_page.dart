import 'dart:async';
import 'dart:convert';
import 'dart:math';

//import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gamesarena/features/games/quiz/widgets/quiz_action_button.dart';
import 'package:gamesarena/features/games/quiz/widgets/quiz_option_button.dart';
import 'package:gamesarena/main.dart';
import 'package:gamesarena/shared/widgets/action_button.dart';

import 'package:gamesarena/features/game/pages/base_game_page.dart';
import 'package:gamesarena/theme/colors.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:openai_dart/openai_dart.dart';

import '../../../../../enums/emums.dart';
import '../../../game/models/game_action.dart';
import '../../../game/pages/game_page.dart';
import '../../../../shared/views/loading_view.dart';
import '../../../../shared/views/loading_view.dart';
import '../models/quiz.dart';
import '../utils/quizzes.dart';

class QuizGamePage extends BaseGamePage {
  static const route = "/quiz";
  final Map<String, dynamic> args;
  final void Function(GameAction gameAction) onActionPressed;
  const QuizGamePage(this.args, this.onActionPressed, {super.key})
      : super(args, onActionPressed);

  @override
  ConsumerState<BaseGamePage> createState() => QuizGamePageState();
}

class QuizGamePageState extends BaseGamePageState<QuizGamePage> {
  bool loadingQuizzes = false;
  List<List<Quiz>> playersQuizzes = [];

  int? selectedAnswer;

  List<Quiz> quizzes = [];

  int questionsLength = 10;
  int currentQuestion = 0;
  int answeredQuestion = -1;

  //OpenAI? openAI;

  late PageController quizPageController;
  Dio dio = Dio();
  int quizGenerateTrialCount = 0;
  int quizGenerateTrialMaxCount = 10;

  Future<List<Quiz>> generateQuizzes() async {
    List<Quiz> quizzes = [];
    try {
      final response = await Gemini.instance.chat([
        Content(parts: [Parts(text: getPrompt())])
      ]);
      final result = response?.content?.parts?.firstOrNull?.text ?? "";
      if (result.isEmpty || !result.contains("[") || !result.contains("]")) {
        return [];
      }

      final jsonString =
          result.substring(result.indexOf("["), result.lastIndexOf("]") + 1);
      //print("jsonString = $jsonString");
      final questionsList = jsonDecode(jsonString) as List;
      quizzes = questionsList.map((e) => Quiz.fromMap(e)).toList();
    } catch (e) {
      print('Error: $e');

      quizGenerateTrialCount++;
      if (quizGenerateTrialCount == quizGenerateTrialMaxCount) {
        return [];
      } else {
        return generateQuizzes();
      }
    }

    return quizzes;
  }

// NB: Keep the questions brief and go straight to the point.
  String getPrompt() {
    return """Generate $questionsLength $gameName questions and answers that can be answered within 60 seconds to at most 5 mins with 4 options and give me the duration that fits the question based on the difficulty level.
    Generate these questions from reliable quiz sites and make sure that answers are very correct. If not sure of the answer get another question instead. I want 100% accurate answers
        I want the quizzes as a list of objects that be converted to json directly from the result using the model class.
        Take note my result should be a json string that once i do a fromJson(result from prompt) i get a List<Quiz> result without any errors
        class Quiz {
  String question;
  List<String> options;
  String answerExplanation;
  int answerIndex;
  int durationInSecs;
  }
  All i want to see in my result is nothing but something like this [{question: "....","options: ["...","...","...","..."],answerExplanation:"...",answerIndex: ...(0-3)",durationInSecs:...(Range >= 60 <= 300)},] in perfect json format without any intro or outro message and thats all
  """;
  }

  void initQuizzes({String? quizzesJson}) async {
    quizGenerateTrialCount = 0;
    currentQuestion = 0;
    answeredQuestion = -1;
    selectedAnswer = null;
    playersQuizzes.clear();

    stopPlayerTime = true;

    if (quizzesJson != null) {
      quizzes = (jsonDecode(quizzesJson) as List)
          .map((e) => Quiz.fromJson(e))
          .toList();
    } else {
      loadingQuizzes = true;
      setState(() {});
      quizzes =
          testQuizzes.skip(10).take(10).map((e) => Quiz.fromMap(e)).toList();
      //quizzes = await generateQuizzes();
      loadingQuizzes = false;
      updateGridDetails(jsonEncode(quizzes));
    }

    for (int i = 0; i < playersSize; i++) {
      playersQuizzes.add([...quizzes]);
      updateCount(i, 0);
    }
    if (quizzes.isNotEmpty) {
      playerTime = quizzes.first.durationInSecs;
      stopPlayerTime = false;
    }

    if (!mounted) return;
    setState(() {});
  }

  Future updateGridDetails(String quizzes) async {
    final details = QuizDetails(quizzes: quizzes);
    await setDetail(details.toMap());
  }

  Future updateDetails(int answer) async {
    final details = QuizDetails(answer: answer);
    await setDetail(details.toMap());
  }

  void selectAnswer(int answer) {
    if (!itsMyTurnToPlay(true)) return;

    selectedAnswer = answer;
    setState(() {});
  }

  void submitAnswer(int? answer, int player,
      [bool isClick = true, String? time]) async {
    if (!itsMyTurnToPlay(isClick, player)) return;

    if (playersQuizzes[player][currentQuestion].selectedAnswer != null) return;

    answer ??= -1;

    playersQuizzes[player][currentQuestion].selectedAnswer = answer;

    if (isClick) {
      updateDetails(answer);
    }

    final unsubmittedPlayers = getUnSubmittedPlayers();
    if (unsubmittedPlayers.isNotEmpty) {
      showPlayerToast(currentPlayer,
          "Submitted, Waiting for ${getPlayersUsernames(unsubmittedPlayers).toStringWithCommaandAnd((t) => t)} to submit");
      setState(() {});
      return;
    }
    await getResults();
  }

  Future getResults() async {
    stopPlayerTime = true;
    setState(() {});

    showPlayerToast(currentPlayer, "And your answer is ...");

    if (!seeking) await Future.delayed(const Duration(seconds: 3));

    for (int i = 0; i < playersSize; i++) {
      if (!isPlayerActive(i)) continue;
      final quiz = playersQuizzes[i][currentQuestion];
      if (quiz.selectedAnswer == quiz.answerIndex) {
        incrementCount(i);
      }
    }
    final quiz = playersQuizzes[currentPlayer][currentQuestion];

    // print(
    //     "currentQuestion = $currentQuestion, selectedAnswer = ${quiz.selectedAnswer}, answer = ${quiz.answerIndex} rightAnswerOption = ${quiz.options[quiz.answerIndex]}, ");

    showPlayerToast(currentPlayer,
        quiz.selectedAnswer == quiz.answerIndex ? "Correct" : "Wrong");

    answeredQuestion = currentQuestion;
    selectedAnswer = null;
    setState(() {});

    if (!seeking) await Future.delayed(const Duration(seconds: 3));

    if (currentQuestion == quizzes.length - 1) {
      currentQuestion = 0;
      scrollToPage();
      updateWinForPlayerWithHighestCount();
    } else {
      showPlayerToast(currentPlayer, "Next Question");
      resetPlayerTime();

      gotoNextQuestion();
    }
  }

  bool get finishedAnsweringQuestions => answeredQuestion >= quizzes.length - 1;

  List<int> getUnSubmittedPlayers([int? question]) {
    List<int> players = [];
    for (int i = 0; i < playersSize; i++) {
      if (isPlayerActive(i) &&
          playersQuizzes[i][question ?? currentQuestion].selectedAnswer ==
              null) {
        players.add(i);
      }
    }
    return players;
  }

  void gotoFirstQuestion() {
    if (currentQuestion == 0) return;
    currentQuestion = 0;
    scrollToPage();
  }

  void gotoLastQuestion() {
    if (currentQuestion == quizzes.length - 1) return;
    currentQuestion = quizzes.length - 1;
    scrollToPage();
  }

  void gotoPreviousQuestion() {
    if (currentQuestion <= 0) return;
    currentQuestion--;
    playerTime = quizzes[currentQuestion].durationInSecs;

    scrollToPage();
  }

  void gotoNextQuestion() {
    if (currentQuestion >= quizzes.length - 1) return;
    currentQuestion++;
    playerTime = quizzes[currentQuestion].durationInSecs;

    scrollToPage();
  }

  void scrollToPage() {
    if (seeking) {
      quizPageController.jumpToPage(currentQuestion);
    } else {
      quizPageController.animateToPage(currentQuestion,
          duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    }

    setState(() {});
  }

  @override
  int? maxGameTime;

  @override
  int? maxPlayerTime;
  @override
  Future onDetailsChange(Map<String, dynamic>? map) async {
    if (map != null) {
      final details = QuizDetails.fromMap(map);
      final answer = details.answer;

      final quizzes = details.quizzes;
      final time = map["time"];
      final playerId = map["id"];
      final player = getPlayerIndex(playerId);

      if (quizzes != null) {
        initQuizzes(quizzesJson: quizzes);
      } else if (answer != null) {
        submitAnswer(answer, player, false, time);
      }
    }
  }

  @override
  void onSpaceBarPressed() {
    if (selectedAnswer != null) {
      submitAnswer(selectedAnswer, currentPlayer);
    }
  }

  @override
  void onKeyEvent(KeyEvent event) {
    if (finishedAnsweringQuestions) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        gotoPreviousQuestion();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        gotoNextQuestion();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        gotoFirstQuestion();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        gotoLastQuestion();
      }
    } else {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (selectedAnswer != null) {
          submitAnswer(selectedAnswer, currentPlayer);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (selectedAnswer == null) {
          selectedAnswer = 0;
          setState(() {});

          return;
        }
        if (selectedAnswer! <= 0) return;
        selectedAnswer = selectedAnswer! - 1;
        setState(() {});
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (selectedAnswer == null) {
          selectedAnswer = 3;
          setState(() {});

          return;
        }
        if (selectedAnswer! >= 3) return;
        selectedAnswer = selectedAnswer! + 1;
        setState(() {});
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (selectedAnswer == null) {
          selectedAnswer = 0;
          setState(() {});

          return;
        }
        if (selectedAnswer! == 0 || selectedAnswer! == 1) return;
        selectedAnswer = selectedAnswer! == 2 ? 0 : 1;
        setState(() {});
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (selectedAnswer == null) {
          selectedAnswer = 3;
          setState(() {});

          return;
        }
        if (selectedAnswer! == 2 || selectedAnswer! == 3) return;
        selectedAnswer = selectedAnswer! == 0 ? 2 : 3;
        setState(() {});
      }
    }
  }

  @override
  void onLeave(int index) {
    // TODO: implement onleaveMatch
  }

  @override
  void onPause() {
    // TODO: implement onPauseGame
  }
  @override
  void onPlayerChange(int player) {
    // TODO: implement onPlayerChange
  }

  @override
  void onInit() {
    initQuizzes();
  }

  @override
  void onResume() {
    // TODO: implement onResume
  }

  @override
  void onStart() {
    //setInitialCount(0);
  }

  @override
  void onConcede(int index) {}

  @override
  void onPlayerTimeEnd() {
    submitAnswer(selectedAnswer, currentPlayer);
  }

  @override
  void onTimeEnd() {}

  @override
  Widget buildBody(BuildContext context) {
    if (loadingQuizzes) {
      return const LoadingView();
    }
    if (playersQuizzes.isEmpty) return Container();
    final quizzes = playersQuizzes[currentPlayer];

    return Center(
      child: AspectRatio(
          aspectRatio: 1 / 1,
          child: RotatedBox(
            quarterTurns: getOppositeLayoutTurn(),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: tint)),
              height: double.infinity,
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    gameName,
                    style: context.headlineLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView.builder(
                        physics: finishedAnsweringQuestions
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        controller: quizPageController,
                        itemCount: quizzes.length,
                        onPageChanged: (page) {
                          currentQuestion = page;
                        },
                        itemBuilder: (context, index) {
                          final quiz = quizzes[index];
                          return Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20, horizontal: 10),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Question ${currentQuestion + 1} / ${quizzes.length}",
                                            style: context.bodyMedium?.copyWith(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            quizzes[currentQuestion].question,
                                            style: context.bodyMedium
                                                ?.copyWith(fontSize: 18),
                                            textAlign: TextAlign.center,
                                          ),
                                          if (index <= answeredQuestion) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              quizzes[currentQuestion]
                                                  .answerExplanation,
                                              style: context.bodySmall
                                                  ?.copyWith(
                                                      fontSize: 14,
                                                      color: lightTint),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 120,
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                child: LayoutBuilder(
                                    builder: (context, constraints) {
                                  return Wrap(
                                    children: List.generate(quiz.options.length,
                                        (qindex) {
                                      final option = quiz.options[qindex];

                                      final rightAnswer =
                                          index > answeredQuestion
                                              ? null
                                              : quiz.answerIndex;

                                      return SizedBox(
                                        width: constraints.maxWidth / 2,
                                        height: 50,
                                        child: QuizOptionButton(
                                            key: Key(option),
                                            option: option,
                                            index: qindex,
                                            selectedAnswer:
                                                playersQuizzes[currentPlayer]
                                                            [index]
                                                        .selectedAnswer ??
                                                    selectedAnswer,
                                            rightAnswer: rightAnswer,
                                            blink: firstTime &&
                                                !finishedAnsweringQuestions &&
                                                qindex != selectedAnswer &&
                                                qindex != rightAnswer,
                                            gameId: gameId,
                                            onPressed: () {
                                              selectAnswer(qindex);
                                            }),
                                      );
                                    }),
                                  );
                                }),
                              )
                            ],
                          );
                        }),
                  ),
                ],
              ),
            ),
          )),
    );
  }

  @override
  Widget buildBottomOrLeftChild(int index) {
    if (index != currentPlayer || playersQuizzes.isEmpty) return Container();
    final quizzes = playersQuizzes[index];
    return RotatedBox(
      quarterTurns: getStraightTurn(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth / 10;
            return Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(
                quizzes.length,
                (index) {
                  final quiz = quizzes[index];
                  return Container(
                    width: width,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == currentQuestion
                          ? lightestTint
                          : Colors.transparent,
                    ),
                    child: SizedBox(
                      height: 16,
                      child: quiz.selectedAnswer == null ||
                              index > answeredQuestion
                          ? null
                          : Icon(
                              quiz.selectedAnswer == quiz.answerIndex
                                  ? EvaIcons.checkmark
                                  : EvaIcons.close,
                              color: quiz.selectedAnswer == quiz.answerIndex
                                  ? Colors.green
                                  : Colors.red,
                              size: 16,
                            ),
                    ),
                  );
                },
              ),
            );
          }),
          if (finishedAnsweringQuestions)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (currentQuestion > 0) ...[
                  QuizActionButton(
                      icon: EvaIcons.arrowhead_left,
                      onPressed: gotoFirstQuestion),
                  QuizActionButton(
                      icon: OctIcons.arrow_left,
                      onPressed: gotoPreviousQuestion),
                ],
                if (currentQuestion < quizzes.length - 1) ...[
                  QuizActionButton(
                      icon: OctIcons.arrow_right, onPressed: gotoNextQuestion),
                  QuizActionButton(
                      icon: EvaIcons.arrowhead_right,
                      onPressed: gotoLastQuestion),
                ]
              ],
            ),
          if (!finishedAnsweringQuestions &&
              selectedAnswer != null &&
              playersQuizzes[currentPlayer][currentQuestion].selectedAnswer ==
                  null)
            ActionButton(height: 50, wrap: true, "Submit", color: Colors.purple,
                onPressed: () {
              submitAnswer(selectedAnswer, currentPlayer);
            })
          else if (!finishedAnsweringQuestions)
            const SizedBox(height: 70),
        ],
      ),
    );
  }

  @override
  void onDispose() {
    quizPageController.dispose();
  }

  @override
  void onInitState() {
    quizPageController = PageController();
  }
}
