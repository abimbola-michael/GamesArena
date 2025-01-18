// import '../../../core/firebase/firestore_methods.dart';
// import '../../game/services.dart';
// import 'models/chess.dart';

// FirestoreMethods fm = FirestoreMethods();

// Future setChessDetails(String gameId,
//     [ChessDetails? details, ChessDetails? prevDetails]) async {
//   Map<String, dynamic> map = {};
//   if (details != null) {
//     // if (details == prevDetails) {
//     //   return //removeGamedetails(gameId);
//     // }

//     if (details == prevDetails) //await removeGamedetails(gameId);
//     map = details.toMap();
//     return fm.setValue(["games", gameId, "details"], value: map);
//   }
// }

// Stream<ChessDetails?> getChessDetails(String gameId) async* {
//   yield* fm.getValueStream(
//       (map) => ChessDetails.fromMap(map), ["games", gameId, "details"]);
// }
