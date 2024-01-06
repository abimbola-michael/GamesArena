import '../models/game_info.dart';

Map<String, GameInfo> gamesInfo = {
  "Whot": GameInfo(
      about:
          "A standard Whot deck contains 54 cards from 5 suits: circles, squares, triangles, stars and crosses. These are numbered between 1 and 14 although not all numbers are included for each suit. The remaining 5 cards are special cards called \"Whot\" cards and designated the number 20",
      rules: [
        "Card is shuffled and 6 cards are shared among each players with a top card to start",
        "Player is only allow to play when it is player's turn",
        "Card 1 means \"Hold On\" which means player has opportunity to play again",
        "Card 2 means \"Pick 2\" which means the next player picks 2 cards from the market with a single tap on the general market",
        "Card 8 means \"Suspension\" which means player suspends the next player and the following player to the next plays, in a 2 players game the player plays again since there is no player to suspend",
        "Card 20 means  \"I need\" which means the player needs a shape",
        "It is required to pick card from market when given pick 2 or general market and not to play",
        "It is required to play the shape that matches the required I need shape",
      ],
      howtoplay: [
        "Tap any card to open your cards and don't reveal to your opponent and note cards automatically closes after playing except when playing online game to avoid unnecessary card revealing",
        "Long press on any card to hide all cards",
        "Scroll left or right to reveal hidden cards",
        "Play any card that matches the played card or wild card (20 Whot) to request for a shape and if don't have pick a card from market",
        "Then your opponent(s) play and play in turns",
        "Play special cards like 2 which means your opponent picks 2 cards, 14 which means your opponent(s) all pick from the general market, 8 to suspend the next player, 1 to hold on all your opponent(s) and play another card again and 20 which gives you opportunity to request a shape that suits you",
        "You win the game when you have played all your cards",
      ]),
  "Chess": GameInfo(
      about:
          "Chess is a two-player board game of strategy and war, played on a checkered board with 64 squares and specially designed pieces of contrasting colors. Each player has a king, a queen, two rooks, two bishops, two knights, and eight pawns, and moves them according to fixed rules. The goal is to force the opponent's king into checkmate, a position where it cannot avoid capture. Chesses are divided into two different colored sets. The players of the sets are referred to as White and Black, respectively. Each set consists of sixteen pieces.",
      rules: [
        "Pawn: A Pawn moves 1 or 2 steps forward for first move and 1 for subsequent moves and 1 step diagonally when about to capture",
        "Rook: A Rook moves 1 or multiple steps edge to edge in top, bottom, left and right direction. Basically rook moves vertically and horizontally",
        "Bishop: A Bishop moves 1 or multiple steps diagonally in top left, top right, bottom left, bottom right direction",
        "Knight: A Knight moves 1 step in one edge and 2 steps in the other edge in all directions. Basically knight moves in a shape of letter L",
        "Queen: A Queen moves 1 or multiple steps in all directions. Basically verically, horizontally and diagonally",
        "King: A King moves 1 step in all directions.  Basically verically, horizontally and diagonally",
        "A chess piece can only make 1 capture at a time",
        "A chess piece captures by landing on the same spot the opponent's piece is and with its specific movement",
        "A pawn has a special move called enpassant which occurs when a player is 2 steps away for the opponents pawn and an opponent's pawn makes its first move 2 steps forward, the players pawn can capture the pawn diagonally as if it is as a capture position and only if its the player's direct next move",
        "A piece is pinned when a piece's movement can lead to a check of the king",
        "A king cannot move to a place of check",
        "When a king is on check no other piece can move except the king moving away from the check position and any other piece that can block the king check",
        "A king can also castle in the king's side when it hasn't made any move and the rook at the king's side also hasn't made any move and there is no piece in between them and also isn't on check or the castle move wouldn't lead to a check. The king castles 2 steps to the right while the rook leave its current position and stay at the left side of the king",
        "A king can also castle in the queen's side when it hasn't made any move and the rook at the queen's side also hasn't made any move and there is no piece in between them and also isn't on check or the castle move wouldn't lead to a check. The king castles 2 steps to the left while the rook leave its current position and stay at the right side of the king",
      ],
      howtoplay: [
        "Tap on any chess piece and make your move",
        "Then your opponent play and play in turns",
        "You goal of the game is to make sure you protect your king with your piece and checkmate your opponent's king",
        "The game is a draw when your opponent don't have any piece to move, when there is 3 repetitive game pattern, when the game ends with a king to a king or a king to a king with a bishop or a rook and when you and your opponent makes 50 moves without capturing",
        "You win the game when your opponent's king is on checkmate meaning can no longer move in any direction",
      ]),
  "Draught": GameInfo(
      about:
          "Draught also called Checkers is a form of the strategy board game. It is played on an 8x8 or 10x10 checkerboard with 12 pieces per side for 8x8 and 20 pieces per side for 10x10. The pieces move and capture diagonally forward, until they reach the opposite end of the board, when they are crowned and can thereafter move only forward and capture both backward and forward",
      rules: [
        "A draught piece moves diagonally 1 step right or left and cannot move backwards",
        "A draught piece cannot make any other move when there is an opportunity for capture",
        "A draught piece captures by flying over the opponents piece and landing the the next empty spot diagonally",
        "A draught piece can make multiple captures at different directions",
        "A draught piece is crowned once it reaches its opponent's end of board",
        "A crowned draught piece can move multiple steps both backward and forward and call also make multiple captures"
      ],
      howtoplay: [
        "Tap on any draught piece and make your move",
        "Then your opponent play and play in turns",
        "Your goal is to capture all your opponent's pieces",
        "When there is an opportunity for multiple capture tap on all the capture spots and tap done selecting if you want to stop or keep tapping till there is no longer possible capture",
        "The game is a draw when your opponent can no longer move but still have pieces on board, when there is 3 repetitive game pattern and when only king is moved 25 times consecutively without capturing",
        "You win the game when your opponent no longer have a piece on board",
      ]),
  "Ludo": GameInfo(
      about:
          "Ludo is a strategy board game for two to four players, in which the players race their four tokens from start to finish according to the rolls of a single die",
      rules: [
        "A ludo can be brought out only when there is a 6 in any of the dice rolled",
        "When it players turn to play, a player cannot play opponent's ludo",
        "The actual number of dice rolled is the number of steps any of the tapped ludo can make, not more not less",
        "When player has no active players and cannot enter house or dice has no 6 its the opponents turn to play",
        "When there is an opponent's ludo at the spot of the ludo step count, the opponent piece is to start its movement round again from ludo house while the players ludo passes and is assumed to have completed all steps",
        "When there is players ludo at the spot of the ludo step count, it is assumed that both player's ludo are at the same spot",
      ],
      howtoplay: [
        "Tap the roll dice button to roll dice",
        "Tap on any ludo to play, If rolled 6 in any of the dice you have an opportunity to bring a ludo out or play your dice count and move steps ahead. You can count the dice seperately or play the total count",
        "Then your opponent(s) play and play in turns",
        "If your ludo step is equal to the spot where your opponent is, your ludo has passed, while your opponent starts again",
        "If your ludo step is equal to your player's spot, your players are combined on that spot",
        "If your ludo has completely gone round the entire board and entered house your ludo passes",
        "You win a point when all your ludos are out of the game"
      ]),
  "X and O": GameInfo(
      about:
          "Xs and Os (Irish English), tic-tac-toe (American English) or noughts and crosses (Commonwealth English) is a paper-and-pencil game for two players who take turns marking the spaces in a three-by-three grid with X or O. The player who succeeds in placing three of their marks in a horizontal, vertical, or diagonal row is the winner",
      rules: [
        "A player cannot play twice, they have to play in turns",
        "A player should look for opportunities for 2 ways to win to make opponent's next move irrelevant",
        "When your opponent is about to complete their 3 pattern mark you are to block their move",
        "A player should look for ways to make a 3 mark pattern to win game",
      ],
      howtoplay: [
        "Tap on any spot on the grid to play your character, either X or O",
        "Then your opponent play and play in turns",
        "You win a point when there is a 3 character pattern in any direction (diagonally, vertically or horizontally)"
      ]),
  "Bat Ball": GameInfo(
      about:
          "Bat ball is a strategy ball game where to players hit ball at each others post and tries to defend when ball is about to cross player's post and player wins when ball crosses opponent's post",
      rules: [
        "A player should drag only half of the screen to and avoid dragging the opponents spot",
      ],
      howtoplay: [
        "Hold and move your finger around the bottom half of your screen to move your bat",
        "While moving hit the ball to any direction and speed to score your opponent",
        "When your opponent hits the ball at you, defend your post",
        "You win a point when you hit the ball pass your opponent's post"
      ]),
};
