// import '../../../core/firebase/firestore_methods.dart';
// import '../../../shared/utils/utils.dart';
// import '../../game/services.dart';
// import 'models/whot.dart';

// FirestoreMethods fm = FirestoreMethods();

// Future setWhotDetails(String gameId,
//     [WhotDetails? details, WhotDetails? prevDetails]) async {
//   Map<String, dynamic> map = {};
//   if (details != null) {
//     if (details == prevDetails) //await removeGamedetails(gameId);
//     map = details.toMap();
//   } else {
//     map = WhotDetails(
//       whotIndices: getRandomIndex(54).join(","),
//       currentPlayerId: "",
//       playPos: -1,
//       shapeNeeded: -1,
//     ).toMap();
//   }
//   return fm.setValue(["games", gameId, "details"], value: map);
// }

// Stream<WhotDetails?> getWhotDetails(String gameId) async* {
//   yield* fm.getValueStream(
//       (map) => WhotDetails.fromMap(map), ["games", gameId, "details"]);
// }

// Future<String> getWhotIndices(String gameId) async {
//   final details = await (fm.getValue(
//       (map) => WhotDetails.fromMap(map), ["games", gameId, "details"]));
//   return details?.whotIndices ?? "";
// }
