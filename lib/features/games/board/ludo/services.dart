// import '../../../core/firebase/firestore_methods.dart';
// import '../../../shared/utils/utils.dart';
// import '../../game/services.dart';
// import 'models/ludo.dart';

// FirestoreMethods fm = FirestoreMethods();

// Future setLudoDetails(String gameId,
//     [LudoDetails? details, LudoDetails? prevDetails]) async {
//   Map<String, dynamic> map = {};
//   if (details != null) {
//     if (details == prevDetails) //await removeGamedetails(gameId);
//     map = details.toMap();
//   } else {
//     map = LudoDetails(
//       ludoIndices: getRandomIndex(4).join(","),
//       currentPlayerId: "",
//       startPos: -1,
//       startPosHouse: -1,
//       endPos: -1,
//       endPosHouse: -1,
//       dice1: -1,
//       dice2: -1,
//       selectedFromHouse: false,
//       enteredHouse: false,
//     ).toMap();
//   }
//   return fm.setValue(["games", gameId, "details"], value: map);
// }

// Stream<LudoDetails?> getLudoDetails(String gameId) async* {
//   yield* fm.getValueStream(
//       (map) => LudoDetails.fromMap(map), ["games", gameId, "details"]);
// }

// Future<String> getLudoIndices(String gameId) async {
//   final details = await (fm.getValue(
//       (map) => LudoDetails.fromMap(map), ["games", gameId, "details"]));
//   return details?.ludoIndices ?? "";
// }
