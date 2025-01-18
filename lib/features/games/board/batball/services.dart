import '../../../../core/firebase/firestore_methods.dart';
import '../../../game/services.dart';
import 'models/batball.dart';

FirestoreMethods fm = FirestoreMethods();

// Future setBatBallDetails(String gameId,
//     [BatBallDetails? details, BatBallDetails? prevDetails]) async {
//   Map<String, dynamic> map = {};
//   if (details != null) {
//     if (details == prevDetails) //await removeGamedetails(gameId);
//     map = details.toMap();
//     return fm.setValue(["games", gameId, "details"], value: map);
//   }
// }

// Stream<BatBallDetails?> getBatBallDetails(String gameId) async* {
//   yield* fm.getValueStream(
//       (map) => BatBallDetails.fromMap(map), ["games", gameId, "details"]);
// }
