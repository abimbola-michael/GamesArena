import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class WordPuzzle {
  int pos;
  int x;
  int y;
  String char;
  WordPuzzle({
    required this.pos,
    required this.x,
    required this.y,
    required this.char,
  });

  WordPuzzle copyWith({
    int? pos,
    int? x,
    int? y,
    String? char,
  }) {
    return WordPuzzle(
      pos: pos ?? this.pos,
      x: x ?? this.x,
      y: y ?? this.y,
      char: char ?? this.char,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pos': pos,
      'x': x,
      'y': y,
      'char': char,
    };
  }

  factory WordPuzzle.fromMap(Map<String, dynamic> map) {
    return WordPuzzle(
      pos: map['pos'] as int,
      x: map['x'] as int,
      y: map['y'] as int,
      char: map['char'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory WordPuzzle.fromJson(String source) => WordPuzzle.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WordPuzzle(pos: $pos, x: $x, y: $y, char: $char)';
  }

  @override
  bool operator ==(covariant WordPuzzle other) {
    if (identical(this, other)) return true;
  
    return 
      other.pos == pos &&
      other.x == x &&
      other.y == y &&
      other.char == char;
  }

  @override
  int get hashCode {
    return pos.hashCode ^
      x.hashCode ^
      y.hashCode ^
      char.hashCode;
  }
}

class WordPuzzleDetails {
  String currentPlayerId;
  String player1Puzzles;
  String player2Puzzles;
  String player1Words;
  String player2Words;
  int startPos;
  int endPos;
  WordPuzzleDetails({
    required this.currentPlayerId,
    required this.player1Puzzles,
    required this.player2Puzzles,
    required this.player1Words,
    required this.player2Words,
    required this.startPos,
    required this.endPos,
  });

  WordPuzzleDetails copyWith({
    String? currentPlayerId,
    String? player1Puzzles,
    String? player2Puzzles,
    String? player1Words,
    String? player2Words,
    int? startPos,
    int? endPos,
  }) {
    return WordPuzzleDetails(
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      player1Puzzles: player1Puzzles ?? this.player1Puzzles,
      player2Puzzles: player2Puzzles ?? this.player2Puzzles,
      player1Words: player1Words ?? this.player1Words,
      player2Words: player2Words ?? this.player2Words,
      startPos: startPos ?? this.startPos,
      endPos: endPos ?? this.endPos,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'currentPlayerId': currentPlayerId,
      'player1Puzzles': player1Puzzles,
      'player2Puzzles': player2Puzzles,
      'player1Words': player1Words,
      'player2Words': player2Words,
      'startPos': startPos,
      'endPos': endPos,
    };
  }

  factory WordPuzzleDetails.fromMap(Map<String, dynamic> map) {
    return WordPuzzleDetails(
      currentPlayerId: map['currentPlayerId'] as String,
      player1Puzzles: map['player1Puzzles'] as String,
      player2Puzzles: map['player2Puzzles'] as String,
      player1Words: map['player1Words'] as String,
      player2Words: map['player2Words'] as String,
      startPos: map['startPos'] as int,
      endPos: map['endPos'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory WordPuzzleDetails.fromJson(String source) =>
      WordPuzzleDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WordPuzzleDetails(currentPlayerId: $currentPlayerId, player1Puzzles: $player1Puzzles, player2Puzzles: $player2Puzzles, player1Words: $player1Words, player2Words: $player2Words, startPos: $startPos, endPos: $endPos)';
  }

  @override
  bool operator ==(covariant WordPuzzleDetails other) {
    if (identical(this, other)) return true;

    return other.currentPlayerId == currentPlayerId &&
        other.player1Puzzles == player1Puzzles &&
        other.player2Puzzles == player2Puzzles &&
        other.player1Words == player1Words &&
        other.player2Words == player2Words &&
        other.startPos == startPos &&
        other.endPos == endPos;
  }

  @override
  int get hashCode {
    return currentPlayerId.hashCode ^
        player1Puzzles.hashCode ^
        player2Puzzles.hashCode ^
        player1Words.hashCode ^
        player2Words.hashCode ^
        startPos.hashCode ^
        endPos.hashCode;
  }
}
