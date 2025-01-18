import 'dart:async';

import 'package:gamesarena/core/firebase/firestore_methods.dart';
import 'package:gamesarena/shared/utils/utils.dart';

import '../../shared/models/app_message.dart';

FirestoreMethods fm = FirestoreMethods();

Stream<AppMessages?> getAppMessageStream() async* {
  yield* fm.getValueStream(
      (map) => AppMessages.fromMap(map), ["public", "appmessage"]);
}

Future updateSeenAnnouncement(String announcement) {
  return fm.updateValue(["users", myId], value: {"announcement": announcement});
}
