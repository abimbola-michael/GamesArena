import 'package:dio/dio.dart';
import 'package:gamesarena/shared/models/event_change.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gamesarena/core/firebase/extensions/firebase_extensions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';

import '../../shared/models/models.dart';

class FirebaseMethods {
  var myId = "";
  FirebaseMethods() {
    getCurrentUserId();
  }
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseDatabase database = FirebaseDatabase.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<UserCredential?> createAccount(String email, String password) async {
    try {
      return auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      return null;
    }
  }

  Future<UserCredential?> login(String email, String password) async {
    try {
      return auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle(
      void Function(String phone) onGetPhoneNumber) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(scopes: [
        "email",
        'https://www.googleapis.com/auth/user.phonenumbers.read',
        'https://www.googleapis.com/auth/userinfo.profile',
      ]).signIn();
      if (googleUser == null) {
        return null;
      }
      String phoneNumber = "";

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // // Fetch additional user info from Google People API
      // final dio = Dio();
      // final peopleResponse = await dio.get(
      //   'https://people.googleapis.com/v1/people/me?personFields=phoneNumbers',
      //   options: Options(
      //     headers: {'Authorization': 'Bearer ${googleAuth.accessToken}'},
      //   ),
      // );

      // if (peopleResponse.statusCode == 200) {
      //   final data = peopleResponse.data as Map<String, dynamic>;
      //   final phoneNumbers = data['phoneNumbers'] ?? [];
      //   if (phoneNumbers.isNotEmpty) {
      //     phoneNumber = phoneNumbers[0]['value'];
      //     print('Phone number: $phoneNumber');
      //   } else {
      //     print('No phone number found');
      //   }
      // } else {
      //   print('Failed to fetch phone number: ${peopleResponse.statusCode}');
      //   return null;
      // }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      onGetPhoneNumber(phoneNumber);

      return FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      return null;
    }
  }

  Future<void> logOut() async {
    await auth.signOut();
    // Sign out and disconnect Google account session
    final GoogleSignIn googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut(); // Sign out
      await googleSignIn.disconnect(); // Disconnect the account
    }
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
    return database.ref(path.join("/"));
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
    } on FirebaseException {}
  }

  Future<void> removeValue(List<String> path,
      {bool Function(Map? map)? callback}) async {
    try {
      final ref = getDatabaseRef(path);
      return ref.remove();
      // return ref.onDisconnect().remove();
    } on FirebaseException {}
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
    } on FirebaseException {
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
    } on FirebaseException {
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
    } on FirebaseException {
      return [];
    }
  }

  Stream<List<T>> getValuesStream<T>(
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
    } on FirebaseException {
      yield [];
    }
  }

  Stream<List<EventChange<T>>> getValuesChangeStream<T>(
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
        final snapshots = MergeStream(
            [ref.onChildAdded, ref.onChildChanged, ref.onChildRemoved]);
        yield* snapshots.map((snapshot) => snapshot.getValuesChanges(callback));
      } else {
        final ref = getDatabaseRef(path);
        final snapshots = ref.onValue;
        yield* snapshots.map((snapshot) => snapshot.getValue(callback) != null
            ? [
                EventChange(
                    type: DatabaseEventType.childAdded,
                    value: snapshot.getValue(callback) as T)
              ]
            : []);
      }
    } on FirebaseException {
      yield [];
    }
  }

  String getId(List<String> path) {
    try {
      final ref = getDatabaseRef(path);
      return ref.push().key ?? "";
    } on FirebaseException {
      return "";
    }
  }
}
