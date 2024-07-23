import 'package:firebase_auth/firebase_auth.dart';
import 'package:gamesarena/core/firebase/firestore_methods.dart';

import '../user/models/username.dart';

FirestoreMethods fm = FirestoreMethods();

Future<bool> usernameExists(String username) async {
  final name = await fm
      .getValue((map) => Username.fromMap(map), ["usernames", username]);
  return name != null;
}

Future createUser(Map<String, dynamic> userMap) async {
  final currentuserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  if (currentuserId.isEmpty) return;

  final username = userMap["username"];

  if (username != null) {
    await fm.setValue(["usernames", username], value: {"username": username});
  }
  if (userMap["user_id"] != null && userMap["user_id"].isEmpty) {
    userMap["user_id"] = currentuserId;
  }
  await fm.setValue(["users", currentuserId], value: userMap);
}

String getCurrentUserId() {
  return FirebaseAuth.instance.currentUser?.uid ?? "";
}
