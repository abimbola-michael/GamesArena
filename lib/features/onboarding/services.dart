import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:gamesarena/core/firebase/firestore_methods.dart';
import 'package:gamesarena/features/user/services.dart';
import 'package:gamesarena/main.dart';
import 'package:gamesarena/shared/utils/utils.dart';

import '../user/models/user.dart';
import '../user/models/username.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

FirestoreMethods fm = FirestoreMethods();

Future<bool> usernameExists(String username) async {
  final name = await fm
      .getValue((map) => Username.fromMap(map), ["usernames", username]);
  return name != null;
}

Future<User> createUserFromAuthUser(auth.User authUser) async {
  final time = timeNow;
  final newUser = User(
    email: authUser.email ?? "",
    user_id: authUser.uid,
    username: "",
    phone: "",
    time_modified: time,
    time: time,
    last_seen: time,
    tokens: [],
    profile_photo: authUser.photoURL,
  );
  await fm
      .setValue(["users", authUser.uid], value: newUser.toMap().removeNull());
  return newUser;
}

Future<Map<String, dynamic>> updateUser(
    String userId, Map<String, dynamic> value) async {
  final time = timeNow;
  final newValue = {...value, "time_modified": time, "last_seen": time};
  await fm.updateValue(["users", userId], value: newValue);
  return newValue;
}

Future createOrUpdateUser(Map<String, dynamic> userMap,
    [auth.User? authUser]) async {
  String currentuserId = authUser?.uid ?? myId;

  final username = userMap["username"] as String?;
  final userId = userMap["user_id"] as String?;

  if (currentuserId.isEmpty && userId != null) {
    currentuserId = userId;
  }
  if (currentuserId.isEmpty) return;

  if (username != null && username.isNotEmpty) {
    await fm.setValue(["usernames", username], value: {"username": username});
  }

  await fm.setValue(["users", currentuserId],
      value: userMap.removeNull(), merge: true);
}

Future deleteUser() async {
  final time = timeNow;
  return fm.updateValue([
    "users",
    myId
  ], value: {
    "tokens": [],
    "time_deleted": time,
    "time_modified": time,
    "last_seen": time
  });
}

Future logoutUser() async {
  final token = sharedPref.getString("token");
  final user = await getUser(myId);
  final tokens = user?.tokens ?? [];
  if (token != null && tokens.contains(token)) {
    tokens.remove(token);
  }
  if (user == null) return;

  final time = timeNow;

  await fm.updateValue(["users", myId],
      value: {"tokens": tokens, "time_modified": time, "last_seen": time});
  sharedPref.remove("token");
}

String getCurrentUserId() {
  return auth.FirebaseAuth.instance.currentUser?.uid ?? "";
}
