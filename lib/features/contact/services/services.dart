import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gamesarena/features/game/services.dart';
import 'package:gamesarena/shared/utils/utils.dart';

import '../../../core/firebase/firestore_methods.dart';
import '../../../shared/models/models.dart';

FirestoreMethods fm = FirestoreMethods();

Future sendPlayerRequest(String phone) {
  return fm.setValue([
    "requests",
    phone
  ], value: {
    "ids": FieldValue.arrayUnion([myId])
  }, merge: true);
}

Future acceptPlayersRequests(String phone) async {
  var ids = await fm
      .getValue((map) => map["ids"] as List<dynamic>, ["requests", phone]);

  if (ids == null) return saveAnsweredReuests();

  ids = ids.toSet().toList();
  List<String> addedIds = [];
  for (int i = 0; i < ids.length; i++) {
    final id = ids[i];
    await addPlayer(id);
    addedIds.add(id);

    if (i == ids.length - 1) {
      await fm.removeValue(["requests", phone]);
    } else if (addedIds.length == 10) {
      await fm.updateValue(["requests", phone],
          value: {"ids": FieldValue.arrayRemove(addedIds)});

      addedIds.clear();
    }
  }

  return saveAnsweredReuests();
}

Future saveAnsweredReuests() {
  return fm.updateValue(["users", myId], value: {"answeredRequests": true});
}

Future<List<User>> getUsersWithNumber(String phone) {
  return fm.getValues((map) => User.fromMap(map), ["users"],
      where: ["phone", "==", phone]);
}
