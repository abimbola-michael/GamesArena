import 'package:gamesarena/core/firebase/firestore_methods.dart';
import 'package:gamesarena/features/games/word_puzzle/models/word_puzzle.dart';

//FirestoreMethods fm = FirestoreMethods();

// Future setWordPuzzleDetails(String gameId, [WordPuzzleDetails? details]) async {
//   Map<String, dynamic> map = {};

//   if (details != null) {
//     map = details.toMap();
//   } else {
//     map = WordPuzzleDetails(
//             currentPlayerId: "",
//             player1Puzzles: player1Puzzles,
//             player2Puzzles: player2Puzzles,
//             startPos: -1,
//             endPos: -1)
//         .toMap();
//   }
//   return fm.setValue(["games", gameId, "details"], value: map);
// }

// Stream<LudoDetails?> getLudoDetails(String gameId) async* {
//   yield* fm.getValueStream(
//       (map) => LudoDetails.fromMap(map), ["games", gameId, "details"]);
// }
