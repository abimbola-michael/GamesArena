// import '../../../core/firebase/firestore_methods.dart';
// import '../../game/services.dart';
// import 'models/draught.dart';

// FirestoreMethods fm = FirestoreMethods();

// Future setDraughtDetails(String gameId,
//     [DraughtDetails? details, DraughtDetails? prevDetails]) async {
//   Map<String, dynamic> map = {};
//   if (details != null) {
//     if (details == prevDetails) //await removeGamedetails(gameId);
//     map = details.toMap();
//     return fm.setValue(["games", gameId, "details"], value: map);
//   }
// }

// Stream<DraughtDetails?> getDraughtDetails(String gameId) async* {
//   yield* fm.getValueStream(
//       (map) => DraughtDetails.fromMap(map), ["games", gameId, "details"]);
// }
