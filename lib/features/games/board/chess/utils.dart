import '../../../../enums/emums.dart';

String getAsset(ChessShape shape) {
  String asset = "";
  if (shape == ChessShape.bishop) {
    asset = "assets/svgs/chess_bishop_icon.svg";
  } else if (shape == ChessShape.knight) {
    asset = "assets/svgs/chess_horse_knight_icon.svg";
  } else if (shape == ChessShape.king) {
    asset = "assets/svgs/chess_king_icon.svg";
  } else if (shape == ChessShape.pawn) {
    asset = "assets/svgs/chess_pawn_icon.svg";
  } else if (shape == ChessShape.queen) {
    asset = "assets/svgs/chess_queen_icon.svg";
  } else if (shape == ChessShape.rook) {
    asset = "assets/svgs/chess_rook_icon.svg";
  }
  return asset;
}
