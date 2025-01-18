import '../../core/firebase/firestore_methods.dart';
import '../utils/utils.dart';

FirestoreMethods fm = FirestoreMethods();

Future startCall(String gameId, String callMode) {
  return fm.updateValue([
    "games",
    gameId,
    "players",
    myId
  ], value: {
    "callMode": callMode,
    "isAudioOn": true,
    "isFrontCamera": true,
    "time_modified": timeNow
  });
}

Future endCall(String gameId) {
  return fm.updateValue([
    "games",
    gameId,
    "players",
    myId
  ], value: {
    "callMode": null,
    "isAudioOn": null,
    "isFrontCamera": null,
    "time_modified": timeNow
  });
}

Future updateCallMode(String gameId, String? callMode) {
  return fm.updateValue(["games", gameId, "players", myId],
      value: {"callMode": callMode, "time_modified": timeNow});
}

Future updateCallAudio(String gameId, bool isAudioOn) {
  return fm.updateValue(["games", gameId, "players", myId],
      value: {"isAudioOn": isAudioOn, "time_modified": timeNow});
}

Future updateCallHold(String gameId, bool isOnHold) {
  return fm.updateValue(["games", gameId, "players", myId],
      value: {"isOnHold": isOnHold, "time_modified": timeNow});
}

Future updateCallCamera(String gameId, bool isFrontCamera) {
  return fm.updateValue(["games", gameId, "players", myId],
      value: {"isFrontCamera": isFrontCamera, "time_modified": timeNow});
}

Stream<List<ValueChange<Map<String, dynamic>>>> streamChangeSignals(
    String gameId) async* {
  yield* fm.getValuesChangeStream(
      (map) => map, ["games", gameId, "players", myId, "signal"],
      order: ["time"]);
}

Future addSignal(
    String gameId, String userId, Map<String, dynamic> value) async {
  return fm.setValue(["games", gameId, "players", userId, "signal", myId],
      value: {...value, "id": myId, "time": timeNow}, merge: true);
}

Future removeSignal(String gameId, String userId) {
  return fm.removeValue(["games", gameId, "players", userId, "signal"]);
}
