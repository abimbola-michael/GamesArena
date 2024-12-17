// import '../../../core/firebase/firestore_methods.dart';
// import '../../game/services.dart';
// import 'models/xando.dart';

// FirestoreMethods fm = FirestoreMethods();

// Future setXandODetails(String gameId,
//     [XandODetails? details, XandODetails? prevDetails]) async {
//   Map<String, dynamic> map = {};
//   if (details != null) {
//     if (details == prevDetails) //await removeGamedetails(gameId);
//     map = details.toMap();
//     return fm.setValue(["games", gameId, "details"], value: map);
//   }
// }

// Stream<XandODetails?> getXandODetails(String gameId) async* {
//   yield* fm.getValueStream(
//       (map) => XandODetails.fromMap(map), ["games", gameId, "details"]);
// }
