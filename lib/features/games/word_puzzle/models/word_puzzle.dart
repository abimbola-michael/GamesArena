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

  factory WordPuzzle.fromJson(String source) =>
      WordPuzzle.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WordPuzzle(pos: $pos, x: $x, y: $y, char: $char)';
  }

  @override
  bool operator ==(covariant WordPuzzle other) {
    if (identical(this, other)) return true;

    return other.pos == pos &&
        other.x == x &&
        other.y == y &&
        other.char == char;
  }

  @override
  int get hashCode {
    return pos.hashCode ^ x.hashCode ^ y.hashCode ^ char.hashCode;
  }
}

class WordPuzzleDetails {
  String currentPlayerId;
  String? playerPuzzles;
  String? playerWords;
  int? startPos;
  int? endPos;
  WordPuzzleDetails({
    required this.currentPlayerId,
    this.playerPuzzles,
    this.playerWords,
    this.startPos,
    this.endPos,
  });

  WordPuzzleDetails copyWith({
    String? currentPlayerId,
    String? playerPuzzles,
    String? playerWords,
    int? startPos,
    int? endPos,
  }) {
    return WordPuzzleDetails(
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      playerPuzzles: playerPuzzles ?? this.playerPuzzles,
      playerWords: playerWords ?? this.playerWords,
      startPos: startPos ?? this.startPos,
      endPos: endPos ?? this.endPos,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'currentPlayerId': currentPlayerId,
      'playerPuzzles': playerPuzzles,
      'playerWords': playerWords,
      'startPos': startPos,
      'endPos': endPos,
    };
  }

  factory WordPuzzleDetails.fromMap(Map<String, dynamic> map) {
    return WordPuzzleDetails(
      currentPlayerId: map['currentPlayerId'] as String,
      playerPuzzles:
          map['playerPuzzles'] != null ? map['playerPuzzles'] as String : null,
      playerWords:
          map['playerWords'] != null ? map['playerWords'] as String : null,
      startPos: map['startPos'] != null ? map['startPos'] as int : null,
      endPos: map['endPos'] != null ? map['endPos'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory WordPuzzleDetails.fromJson(String source) =>
      WordPuzzleDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WordPuzzleDetails(currentPlayerId: $currentPlayerId, playerPuzzles: $playerPuzzles, playerWords: $playerWords, startPos: $startPos, endPos: $endPos)';
  }

  @override
  bool operator ==(covariant WordPuzzleDetails other) {
    if (identical(this, other)) return true;

    return other.currentPlayerId == currentPlayerId &&
        other.playerPuzzles == playerPuzzles &&
        other.playerWords == playerWords &&
        other.startPos == startPos &&
        other.endPos == endPos;
  }

  @override
  int get hashCode {
    return currentPlayerId.hashCode ^
        playerPuzzles.hashCode ^
        playerWords.hashCode ^
        startPos.hashCode ^
        endPos.hashCode;
  }
}
