import 'package:gamesarena/core/firebase/firestore_methods.dart';

import '../../../shared/utils/utils.dart';
import '../game/models/player.dart';
import 'models/group.dart';

FirestoreMethods fm = FirestoreMethods();

Future creatGroup(Group group, List<String> players) async {
  String groupId = group.group_id;
  players.insert(0, myId);
  await fm.setValue(["groups", groupId], value: group.toMap());

  if (players.isNotEmpty) {
    for (var id in players) {
      final player = Player(id: id, time: timeNow);
      await fm
          .setValue(["groups", groupId, "players", id], value: player.toMap());
    }
  }
}

Stream<Group?> getStreamGroup(String groupId) async* {
  yield* fm
      .getValueStream<Group>((map) => Group.fromMap(map), ["groups", groupId]);
}

Future<Group?> getGroup(String groupId) async {
  return fm.getValue<Group>((map) => Group.fromMap(map), ["groups", groupId]);
}

Future<Group?> searchGroup(String type, String searchString) async {
  final groups = await fm.getValues<Group>(
      (map) => Group.fromMap(map), ["groups"],
      where: [type, "==", searchString]);
  return groups.isNotEmpty ? groups.first : null;
}
