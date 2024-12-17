// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class Quiz {
  String question;
  List<String> options;
  String answerExplanation;
  int answerIndex;
  int durationInSecs;
  int? selectedAnswer;
  Quiz({
    required this.question,
    required this.options,
    required this.answerExplanation,
    required this.answerIndex,
    required this.durationInSecs,
    this.selectedAnswer,
  });

  Quiz copyWith({
    String? question,
    List<String>? options,
    String? answerExplanation,
    int? answerIndex,
    int? durationInSecs,
    int? selectedAnswer,
  }) {
    return Quiz(
      question: question ?? this.question,
      options: options ?? this.options,
      answerExplanation: answerExplanation ?? this.answerExplanation,
      answerIndex: answerIndex ?? this.answerIndex,
      durationInSecs: durationInSecs ?? this.durationInSecs,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'question': question,
      'options': options,
      'answerExplanation': answerExplanation,
      'answerIndex': answerIndex,
      'durationInSecs': durationInSecs,
      'selectedAnswer': selectedAnswer,
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      question: map['question'] as String,
      options: List<String>.from((map['options'] as List<dynamic>)),
      answerExplanation: map['answerExplanation'] as String,
      answerIndex: map['answerIndex'] as int,
      durationInSecs: map['durationInSecs'] as int,
      selectedAnswer:
          map['selectedAnswer'] != null ? map['selectedAnswer'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Quiz.fromJson(String source) =>
      Quiz.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Quiz(question: $question, options: $options, answerExplanation: $answerExplanation, answerIndex: $answerIndex, durationInSecs: $durationInSecs, selectedAnswer: $selectedAnswer)';
  }

  @override
  bool operator ==(covariant Quiz other) {
    if (identical(this, other)) return true;

    return other.question == question &&
        listEquals(other.options, options) &&
        other.answerExplanation == answerExplanation &&
        other.answerIndex == answerIndex &&
        other.durationInSecs == durationInSecs &&
        other.selectedAnswer == selectedAnswer;
  }

  @override
  int get hashCode {
    return question.hashCode ^
        options.hashCode ^
        answerExplanation.hashCode ^
        answerIndex.hashCode ^
        durationInSecs.hashCode ^
        selectedAnswer.hashCode;
  }
}

class QuizDetails {
  String? quizzes;
  int? answer;
  QuizDetails({
    this.quizzes,
    this.answer,
  });

  QuizDetails copyWith({
    String? quizzes,
    int? answer,
  }) {
    return QuizDetails(
      quizzes: quizzes ?? this.quizzes,
      answer: answer ?? this.answer,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'quizzes': quizzes,
      'answer': answer,
    };
  }

  factory QuizDetails.fromMap(Map<String, dynamic> map) {
    return QuizDetails(
      quizzes: map['quizzes'] != null ? map['quizzes'] as String : null,
      answer: map['answer'] != null ? map['answer'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory QuizDetails.fromJson(String source) =>
      QuizDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'QuizDetails(quizzes: $quizzes, answer: $answer)';

  @override
  bool operator ==(covariant QuizDetails other) {
    if (identical(this, other)) return true;

    return other.quizzes == quizzes && other.answer == answer;
  }

  @override
  int get hashCode => quizzes.hashCode ^ answer.hashCode;
}
