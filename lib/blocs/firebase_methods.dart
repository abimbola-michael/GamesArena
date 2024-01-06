import 'package:gamesarena/extensions/extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/models.dart';

class FirebaseMethods {
  var myId = "";
  FirebaseMethods() {
    getCurrentUserId();
  }
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseDatabase database = FirebaseDatabase.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<UserCredential> createAccount(String email, String password) async {
    return auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> login(String email, String password) async {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> logOut() async {
    return auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    final user = auth.currentUser;
    return user?.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    final user = auth.currentUser;
    return user?.emailVerified ?? false;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    return auth.sendPasswordResetEmail(email: email);
  }

  Future<void> setPrivacy(String type, int value) async {
    setValue(["users", myId], value: {"privacy.$type": value});
  }

  String getCurrentUserId() {
    myId = auth.currentUser?.uid ?? "";
    return myId;
  }

  Future<void> deleteAccount() async {
    final user = auth.currentUser;
    return user?.delete();
  }

  bool isValidEmail(String email) {
    final pattern = RegExp("^[_A-Za-z0-9-\\+]+(\\.[_A-Za-z0-9-]+)*@"
        "[A-Za-z0-9-]+(\\.[A-Za-z0-9]+)*(\\.[A-Za-z]{2,})\$");
    return pattern.hasMatch(email);
  }

  String? checkValidity(
      String string, String type, int minLength, int maxLength,
      {bool exists = false}) {
    if (string.isEmpty) {
      return "${type.capitalize} cannot be empty";
    } else if (minLength != 0 && string.length < minLength) {
      return "${type.capitalize} must be more than $minLength characters";
    } else if (maxLength != 0 && string.length > maxLength) {
      return "${type.capitalize} must be less than $maxLength characters";
    } else if (type == "email" && !isValidEmail(string)) {
      return "Invalid Email. Check again";
    } else if (type == "password" && exists) {
      return "Password Incorrect";
    } else if (type == "username" && !string.startWithLetter()) {
      return "Username can only start with a letter";
    } else if (type == "username" && string.containsSymbol(["_", "-", "."])) {
      return "Username cannot contain symbol except an underscore, an hyphen or a dot";
    } else if (type == "username" &&
        string.exceededSymbolCount(["_", "-", "."])) {
      return "Username can contain only 1 underscore or 1 hyphen or 1 dot";
    } else if (type == "username" && !string.endsWithLetterOrNumber()) {
      return "Username can only end with letter or number";
    }
    //  else if (type == "username" && string.hasNumberInternally()) {
    //   return "Username can end with number but should not have number in between";
    // }
    else if (exists) {
      return "${type.capitalize} already exist";
    }
    return null;
  }

  Future<bool> checkIfUsernameExists(String username) async {
    final name =
        await getValue((map) => Username.fromMap(map), ["usernames", username]);
    return name != null;
  }

  Future<bool> checkIfEmailExists(String email) async {
    final task = await auth.fetchSignInMethodsForEmail(email);
    return task.length == 1;
  }

  Future<bool> comfirmPassword(String password) async {
    final user = auth.currentUser;
    if (user == null) return false;
    final credential =
        EmailAuthProvider.credential(email: user.email!, password: password);
    final credentialresult =
        await user.reauthenticateWithCredential(credential);
    return credentialresult.user != null;
  }

  Future<void> updateEmail(String email) async {
    final user = auth.currentUser;
    return user?.updateEmail(email);
  }

  Future<void> updatePassword(String password) async {
    final user = auth.currentUser;
    return user?.updatePassword(password);
  }

  DatabaseReference getDatabaseRef(List<String> path) {
    switch (path.length) {
      case 0:
        return database.ref();
      case 1:
        return database.ref(path[0]);
      case 2:
        return database.ref(path[0]).child(path[1]);
      case 3:
        return database.ref(path[0]).child(path[1]).child(path[2]);
      case 4:
        return database
            .ref(path[0])
            .child(path[1])
            .child(path[2])
            .child(path[3]);
      case 5:
        return database
            .ref(path[0])
            .child(path[1])
            .child(path[2])
            .child(path[3])
            .child(path[4]);
      case 6:
        return database
            .ref(path[0])
            .child(path[1])
            .child(path[2])
            .child(path[3])
            .child(path[4])
            .child(path[5]);
      case 7:
        return database
            .ref(path[0])
            .child(path[1])
            .child(path[2])
            .child(path[3])
            .child(path[4])
            .child(path[5])
            .child(path[6]);
      case 8:
        return database
            .ref(path[0])
            .child(path[1])
            .child(path[2])
            .child(path[3])
            .child(path[4])
            .child(path[5])
            .child(path[6])
            .child(path[7]);
      case 9:
        return database
            .ref(path[0])
            .child(path[1])
            .child(path[2])
            .child(path[3])
            .child(path[4])
            .child(path[5])
            .child(path[6])
            .child(path[7])
            .child(path[8]);
      case 10:
        return database
            .ref(path[0])
            .child(path[1])
            .child(path[2])
            .child(path[3])
            .child(path[4])
            .child(path[5])
            .child(path[6])
            .child(path[7])
            .child(path[8])
            .child(path[9]);
    }

    return database
        .ref(path[0])
        .child(path[1])
        .child(path[2])
        .child(path[3])
        .child(path[4])
        .child(path[5])
        .child(path[6])
        .child(path[7])
        .child(path[8])
        .child(path[9])
        .child(path[10]);
  }

  Future<void> setValue(List<String> path,
      {required Map<String, dynamic> value,
      Map<String, dynamic>? onDisconnectValue,
      bool update = false,
      bool withOndisconnect = false}) async {
    try {
      final ref = getDatabaseRef(path);
      if (update) {
        return withOndisconnect
            ? ref.onDisconnect().update(value)
            : ref.update(value);
      } else {
        return withOndisconnect
            ? ref.onDisconnect().set(value)
            : ref.set(value);
      }
    } on Exception catch (e) {}
  }

  Future<void> removeValue(List<String> path,
      {bool Function(Map? map)? callback}) async {
    try {
      final ref = getDatabaseRef(path);
      return ref.remove();
      // return ref.onDisconnect().remove();
    } on Exception catch (e) {}
  }

  Future<T?> getValue<T>(
      T Function(Map<String, dynamic> map) callback, List<String> path,
      [bool isCollection = false]) async {
    try {
      if (path.length.isOdd && isCollection) {
        final ref = getDatabaseRef(path);
        final snapshot = await ref.get();
        return snapshot.getValues(callback).last;
      } else {
        final ref = getDatabaseRef(path);
        final snapshot = await ref.get();
        return snapshot.getValue(callback);
      }
    } on Exception catch (e) {
      return null;
    }
  }

  Stream<T?> getStreamValue<T>(
      T Function(Map<String, dynamic> map) callback, List<String> path,
      [bool isCollection = false]) async* {
    try {
      if (path.length.isOdd && isCollection) {
        final ref = getDatabaseRef(path);
        final snapshots = ref.onValue;
        yield* snapshots.map((snapshot) => snapshot.getValues(callback).last);
      } else {
        final ref = getDatabaseRef(path);
        final snapshots = ref.onValue;
        yield* snapshots.map((snapshot) => snapshot.getValue(callback));
      }
    } on Exception catch (e) {
      yield null;
    }
  }

  Future<List<T>> getValues<T>(
      T Function(Map<String, dynamic> map) callback, List<String> path,
      {List<dynamic>? where,
      List<dynamic>? order,
      List<dynamic>? start,
      List<dynamic>? end,
      List<dynamic>? limit}) async {
    try {
      if (path.length.isOdd) {
        final ref =
            getDatabaseRef(path).getQuery(where, order, start, end, limit);
        final snapshot = await ref.get();
        return snapshot.getValues(callback);
      } else {
        final ref = getDatabaseRef(path);
        final snapshot = await ref.get();
        return snapshot.getValue(callback) != null
            ? [snapshot.getValue(callback) as T]
            : [];
      }
    } on Exception catch (e) {
      return [];
    }
  }

  Stream<List<T>> getStreamValues<T>(
      T Function(Map<String, dynamic> map) callback, List<String> path,
      {List<dynamic>? where,
      List<dynamic>? order,
      List<dynamic>? start,
      List<dynamic>? end,
      List<dynamic>? limit}) async* {
    try {
      if (path.length.isOdd) {
        final ref =
            getDatabaseRef(path).getQuery(where, order, start, end, limit);
        final snapshots = ref.onValue;
        yield* snapshots.map((snapshot) => snapshot.getValues(callback));
      } else {
        final ref = getDatabaseRef(path);
        final snapshots = ref.onValue;
        yield* snapshots.map((snapshot) => snapshot.getValue(callback) != null
            ? [snapshot.getValue(callback) as T]
            : []);
      }
    } on Exception catch (e) {
      yield [];
    }
  }

  String getId(List<String> path) {
    try {
      final ref = getDatabaseRef(path);
      return ref.push().key ?? "";
    } on Exception catch (e) {
      return "";
    }
  }
}
