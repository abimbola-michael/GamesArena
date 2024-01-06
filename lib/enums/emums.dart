
enum Direction { up, down, left, right }

enum DraughtDirection {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
}

enum KingDirection {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
  top,
  bottom,
  left,
  right,
}

enum ChessDirection {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
  top,
  bottom,
  left,
  right,
  topTopRight,
  topTopLeft,
  topLeftLeft,
  topRightRight,
  bottomRightRight,
  bottomLeftLeft,
  bottomBottomRight,
  bottomBottomLeft,
  noDirection,
}

enum KnightChessDirection {
  topTopRight,
  topTopLeft,
  topLeftLeft,
  topRightRight,
  bottomRightRight,
  bottomLeftLeft,
  bottomBottomRight,
  bottomBottomLeft,
}

enum KingCheckDirection {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
  top,
  bottom,
  left,
  right,
  topTopRight,
  topTopLeft,
  topLeftLeft,
  topRightRight,
  bottomRightRight,
  bottomLeftLeft,
  bottomBottomRight,
  bottomBottomLeft,
}

enum BallHitPoint { x, y }

enum GameMode { idle, loading, playing, paused }

enum WhotCardShape { circle, triangle, cross, square, star, whot }

enum ShapeType { circle, triangle, cross, square, star }

enum WhotCardVisibility { visible, hidden, turned }

enum ChessShape { pawn, bishop, rook, knight, king, queen }

enum LudoColor { yellow, green, red, blue }

enum LudoDirection { down, up, left, right }

enum LudoHousePosition {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
}

enum XandOChar { x, o, empty }

enum XandOWinDirection { vertical, horizontal, lowerDiagonal, upperDiagonal }

enum LineDirection { vertical, horizontal, lowerDiagonal, upperDiagonal }

enum PlayerType { noplayer, one, two, three, four }
