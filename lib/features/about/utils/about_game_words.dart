import 'package:gamesarena/shared/utils/constants.dart';

import '../../game/models/game_info.dart';

Map<String, GameInfo> get gamesInfo => {
      quizGame: quizGameInfo(),
      whotGame: GameInfo(
          about:
              "A standard Whot deck contains 54 cards from 5 suits: circles, squares, triangles, stars and crosses. These are numbered between 1 and 14 although not all numbers are included for each suit. The remaining 5 cards are special cards called \"Whot\" cards and designated the number 20",
          rules: [
            "Card is shuffled and 6 cards are shared among each players with a top card to start",
            "A player is only allowed to play when it is players's turn",
            "Card 1 means \"Hold On\" which means players has opportunity to play again",
            "Card 8 means \"Suspension\" which means players suspends the next players and the following players to the next plays, in a 2 players game the players plays again since there is no players to suspend",
            "Card 20 means \"I need\" which means the players needs a shape",
            "Card 14 means \"General Market\" which means all players pick a card from the market",
            "Card 2 means \"Pick 2\" which means the next players picks 2 cards from the market with a single tap on the general market",
            "Card 5 means \"Pick 3\" which means the next players picks 3 cards from the market with a single tap on the general market",
            "When given pick 2 or 3, you are to pick or stack it another pick 2 and same goes for pick 3 with card 5",
            "You can play multiple cards if they have the same number with the call card called the double decking move",
            "The double decking move works for all cards except 20, 1 and 8.",
            "You can play multiple pick 2s, pick 3s, general markets as much as you like",
            "It is required to play the shape that matches the required I need shape",
            "You win the game when you have played all your cards",
            "The whole game then tenders if more than 2 players and determines the positions in the round based on lowest amount of total card numbers",
            "Note that Whot is a game that has several rules based on the players choice. You have the opportunity to use all or agree on the ones you want to use and unuse. Its a free world",
            "Enjoy according to your choice of rules as you play",
          ],
          howtoplay: [
            "Tap or Double Tap any card to open your cards and don't reveal to your opponent and note cards automatically closes after players except when players online game to avoid unnecessary card revealing",
            "Double Tap on any card to hide all cards",
            "Long press on any card to start selecting multiple cards and keep tapping to select and click the checkmark button when done",
            "Scroll left or right to reveal hidden cards",
            "Play any card that matches the played card or wild card (20 Whot) to request for a shape and if don't have pick a card from market",
            "Then your opponent(s) play and play in turns",
            "Play special cards like 2 which means your opponent picks 2 cards, 5 which means your opponent picks 3 cards, 14 which means your opponent(s) all pick 1 from the general market, 8 to suspend the next players, 1 to hold on all your opponent(s) and play another card again and 20 which gives you opportunity to request a shape that suits you",
          ]),
      chessGame: GameInfo(
          about:
              "Chess is a two-players board game of strategy and war, played on a checkered board with 64 squares and specially designed pieces of contrasting colors. Each players has a king, a queen, two rooks, two bishops, two knights, and eight pawns, and moves them according to fixed rules. The goal is to force the opponent's king into checkmate, a position where it cannot avoid capture. Chesses are divided into two different colored sets. The players of the sets are referred to as White and Black, respectively. Each set consists of sixteen pieces.",
          rules: [
            "A chess board of 8 by 8 grid is presented with player 1 pieces and the top (black) and player 2 pieces at the bottom (white) with 16 pieces for each player",
            "Each player has a t0 minutes timer and whoever time runs out first has lost the game and opponent wins",
            "Pawn: A Pawn moves 1 or 2 steps forward for first move and 1 for subsequent moves and 1 step diagonally when about to capture",
            "Rook: A Rook moves 1 or multiple steps edge to edge in top, bottom, left and right direction. Basically rook moves vertically and horizontally",
            "Bishop: A Bishop moves 1 or multiple steps diagonally in top left, top right, bottom left, bottom right direction",
            "Knight: A Knight moves 1 step in one edge and 2 steps in the other edge in all directions. Basically knight moves in a shape of letter L",
            "Queen: A Queen moves 1 or multiple steps in all directions. Basically verically, horizontally and diagonally",
            "King: A King moves 1 step in all directions.  Basically verically, horizontally and diagonally",
            "A chess piece can only make 1 capture at a time",
            "A chess piece captures by landing on the same spot the opponent's piece is and with its specific movement",
            "A pawn has a special move called enpassant which occurs when a players is 2 steps away for the opponents pawn and an opponent's pawn makes its first move 2 steps forward, the players pawn can capture the pawn diagonally as if it is as a capture position and only if its the players's direct next move",
            "A piece is pinned when a piece's movement can lead to a check of the king",
            "A king cannot move to a place of check",
            "When a king is on check no other piece can move except the king moving away from the check position and any other piece that can block the king check",
            "A king can also castle in the king's side when it hasn't made any move and the rook at the king's side also hasn't made any move and there is no piece in between them and also isn't on check or the castle move wouldn't lead to a check. The king castles 2 steps to the right while the rook leave its current position and stay at the left side of the king",
            "A king can also castle in the queen's side when it hasn't made any move and the rook at the queen's side also hasn't made any move and there is no piece in between them and also isn't on check or the castle move wouldn't lead to a check. The king castles 2 steps to the left while the rook leave its current position and stay at the right side of the king",
            "You goal of the game is to make sure you protect your king with your piece and checkmate your opponent's king",
            "The game is a draw when your opponent don't have any piece to move, when there is 3 repetitive game pattern, when the game ends with a king to a king or a king to a king with a bishop or a rook and when you and your opponent makes 50 moves without capturing",
            "You win the game when your opponent's king is on checkmate meaning can no longer move in any direction",
          ],
          howtoplay: [
            "Tap on any chess piece and make your move",
            "Then your opponent play and play in turns",
          ]),
      draughtGame: GameInfo(
          about:
              "Draught also called Checkers is a form of the strategy board game. It is played on an 8x8 or 10x10 checkerboard with 12 pieces per side for 8x8 and 20 pieces per side for 10x10. The pieces move and capture diagonally forward, until they reach the opposite end of the board, when they are crowned and can thereafter move only forward and capture both backward and forward",
          rules: [
            "A draught board of 10 by 10 grid is presented with player 1 pieces and the top (wine) and player 2 pieces at the bottom (yellow) with 20 pieces for each player",
            "Each player has a t0 minutes timer and whoever time runs out first has lost the game and opponent wins",
            "A draught piece moves diagonally 1 step right or left and cannot move backwards",
            "A draught piece cannot make any other move when there is an opportunity for capture",
            "A draught piece captures by jumping over the opponents piece and landing the the next empty spot diagonally",
            "A draught piece can make multiple captures at different directions",
            "A draught piece is crowned once it reaches its opponent's end of board",
            "Your goal is to capture all your opponent's pieces",
            "A crowned draught piece can move multiple steps both backward and forward and call also make multiple captures",
            "The game is a draw when your opponent can no longer move but still have pieces on board, when there is 3 repetitive game pattern and when only remaining king is moved 25 times consecutively without capturing",
            "You win the game when your opponent no longer have a piece on board or better put captured all your opponents' pieces",
          ],
          howtoplay: [
            "Tap on any draught piece and make your move",
            "Then your opponent play and play in turns",
            "When there is an opportunity for multiple capture tap at the end of your capture",
          ]),
      ludoGame: GameInfo(
          about:
              "Ludo is a strategy board game for two to four players, in which the players race their four tokens from start to finish according to the rolls of a single die",
          rules: [
            "A ludo board is presented to players with 4 houses with color yellow, green, red, blue when going clockwise",
            "A ludo can be brought out only when there is a 6 in any of the dice rolled",
            "When it players turn to play, a players cannot play opponent's ludo",
            "The actual number of dice rolled is the number of steps any of the tapped ludo can make, not more not less",
            "When players has no active players and cannot enter house and rolled dice has no 6 its the opponents turn to play",
            // "When there is an opponent's ludo at the spot of the ludo step count, the opponent piece is to start its movement round again from ludo house while the players ludo passes and is assumed to have completed all steps",
            // "When there is the same players' ludo at the spot of the ludo step count, it is assumed that both players's ludo are at the same spot",
            "If your ludo step is equal to your opponents' spot, your ludo has passed, while your opponent starts again",
            "If your ludo step is equal to your players' spot, your players are combined on that spot",
            "If your ludo has completely gone round the entire board and entered house your ludo passes",
            "You win a point when all your ludos are out of the game",
          ],
          howtoplay: [
            "Tap the roll dice button to roll dice",
            "Tap on any ludo to play, If rolled 6 in any of the dice you have an opportunity to bring a ludo out or play your dice count and move steps ahead. You can count the dice seperately or play the total count",
            "Then your opponent(s) play and play in turns",
          ]),
      xandoGame: GameInfo(
          about:
              "Xs and Os (Irish English), tic-tac-toe (American English) or noughts and crosses (Commonwealth English) is a paper-and-pencil game for two players who take turns marking the spaces in a three-by-three grid with X or O. The players who succeeds in placing three of their marks in a horizontal, vertical, or diagonal row is the winner",
          rules: [
            "The game board is a 3 by 3 grid where players simultaneously",
            "A players cannot play twice, they have to play in turns",
            "A player cannot play on a spot that has been played on again",
            "A players should look for opportunities for 2 ways to win to make opponent's next move irrelevant",
            "When your opponent is about to complete their 3 pattern mark you are to block their move by playing on any of the pattern's spot",
            "A players should look for ways to make a 3 mark pattern to win game",
            "You win a point when there is a 3 character pattern in any direction (diagonally, vertically or horizontally)",
            "At the end of the timer the player with the highest points win",
          ],
          howtoplay: [
            "Tap on any spot on the grid to play your character, either X or O. Anybody can be X or O",
            "Then your opponent play and play in turns",
          ]),
      wordPuzzleGame: GameInfo(
          about:
              "Word Puzzle is a popular word game that challenges players to form words by connecting letters in a grid. It can be played solo or in a group, with the goal of finding as many words as possible within a limited time or move set. The game is both entertaining and educational, helping players enhance their vocabulary and problem-solving skills.",
          howtoplay: [
            "The objective is to connect adjacent letters (horizontally, vertically, or diagonally) to form valid words",
            // "Each word must contain at least two or more letters, depending on the game version",
            // "Players score points based on the length and complexity of the words formed",
            "The game ends when time runs out or all words are found",
          ],
          rules: [
            "Players are presented with a 15 by 15 grid of scrambled letters and 20 different words to find",
            "Words must exist in the game’s words",
            "Letters must be adjacent to each other to form a word",
            // "Each letter can only be used once per word",
          ]),
      "Bat Ball": GameInfo(
          about:
              "Bat ball is a strategy ball game where to players hit ball at each others post and tries to defend when ball is about to cross players's post and players wins when ball crosses opponent's post",
          rules: [
            "A players should drag only half of the screen to and avoid dragging the opponents spot",
          ],
          howtoplay: [
            "Hold and move your finger around the bottom half of your screen to move your bat",
            "While moving hit the ball to any direction and speed to score your opponent",
            "When your opponent hits the ball at you, defend your post",
            "You win a point when you hit the ball pass your opponent's post"
          ]),
    };

GameInfo quizGameInfo() {
  return GameInfo(
      about:
          "The Quiz Game contains 10 questions and requires answers for all questions until completed",
      rules: [
        "Players are presented with 10 quiz questions to answer",
        "Player must get at least 5 right to pass and if playing with someone the winner is the one with the highest point",
        "Once you submit the answer to a question you can't resubmit so be sure to check very well before submitting",
        "A time is assigned based on the difficulty of the question, so make sure you select something before the time for the question runs out",
        "Even if you don't click submit your selection option would be submitted for you",
        "No cheating by trying to get the answer to the questions online. Let's play a fair game based on our intelligence",
      ],
      howtoplay: [
        "Read the quiz question carefully and give your answer to the question",
        "Tap on the option that you think is the right answer to the quiz question",
        "If you are very sure of your answer. Submit by tapping the checkmark button",
        "Once submitted, you would no longer be able to change your option",
        "Even if you don't click submit, any option selected before submiting would be used as your answer to the question",
        "Then your opponent(s) play and play in turns",
        "At the end the game after answering all questions the result would be calculated based on the player with the highest point",
        "You win the game when you have the highest point in the quiz game compared to your opponents and must pass 5 points",
      ]);
}
