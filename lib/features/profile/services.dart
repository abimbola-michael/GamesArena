import 'package:gamesarena/shared/utils/utils.dart';

import '../../core/firebase/firestore_methods.dart';

FirestoreMethods fm = FirestoreMethods();

Future updateProfilePhoto(String url) async {
  return fm.updateValue(["users", myId], value: {"profile_photo": url});
}

Future removeProfilePhoto() async {
  return fm.updateValue(["users", myId], value: {"profile_photo": null});
}
