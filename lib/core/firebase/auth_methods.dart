import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gamesarena/shared/utils/utils.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../main.dart';

class AuthMethods {
  var myId = "";
  AuthMethods() {
    getCurrentUserId();
  }
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: <String>[
        'email',
        'profile',
        // PeopleServiceApi.contactsReadonlyScope
      ],
      clientId: isDesktop
          ? '29371509294-q9glv8oegtn4jpm80htu2v6fqse0rbvt.apps.googleusercontent.com'
          : kIsWeb
              ? "29371509294-7770ev42v6v5nuun4t99uu0qpbrouqdh.apps.googleusercontent.com"
              : null
      // clientId:
      //     "182221656090-9phi32s2nujj8fk5dvcu36anp07u9sg8.apps.googleusercontent.com",
      );

  Future<UserCredential?> createAccount(String email, String password) async {
    try {
      return _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseException catch (e) {
      return null;
    }
  }

  Future<UserCredential?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      // if (credential != null) {
      //   await userCredential.user?.linkWithCredential(credential);
      // }
      return userCredential;
    } on FirebaseException catch (e) {
      return null;
    }
  }

  Future<User?> signInWithGoogle(
      {void Function(AuthCredential? credential, String? email)?
          onAccountExist}) async {
    GoogleSignInAccount? googleUser;
    try {
      // Trigger the Google Sign-In process
      googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      // Obtain the authentication details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a credential for Firebase authentication
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Return the signed-in user
      return userCredential.user;
    } catch (e) {
      if (e is FirebaseAuthException &&
          e.code == 'account-exists-with-different-credential') {
        if (onAccountExist != null) {
          onAccountExist(e.credential, e.email);
        }
      } else {
        if (googleUser != null) {
          _googleSignIn.signOut();
          _googleSignIn.disconnect();
        }
      }

      print("Error signing in with Google: $e");
      return null;
    }
  }

  bool get isPasswordAuthentication =>
      _auth.currentUser?.providerData.first.providerId == "password";

  bool get hasPasswordAuthentication =>
      _auth.currentUser?.providerData
          .where((info) => info.providerId == "password")
          .isNotEmpty ??
      false;

  Future<void> logOut() async {
    try {
      // await _auth.currentUser?.reload();

      // final provider = _auth.currentUser?.providerData.firstOrNull?.providerId;

      await _auth.signOut();
      // Sign out and disconnect Google account session
      // if (!kIsWeb && Platform.isWindows) return;

      // if (provider != null && provider.contains("google")) {
      //await _googleSignIn.isSignedIn()
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut(); // Sign out
        await _googleSignIn.disconnect(); // Disconnect the account
        //   }
      }
      await _auth.currentUser?.reload();
    } on FirebaseException catch (e) {}
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    try {
      return user?.sendEmailVerification();
    } on FirebaseException catch (e) {}
  }

  bool get emailVerified {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    try {
      if (user != null && !user.emailVerified) {
        await user.reload();
      }
    } catch (e) {}
    return user?.emailVerified ?? false;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      return _auth.sendPasswordResetEmail(email: email);
    } on FirebaseException catch (e) {}
  }

  String getCurrentUserId() {
    myId = _auth.currentUser?.uid ?? "";
    return myId;
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    try {
      return user?.delete();
    } on FirebaseException catch (e) {}
  }

  Future<bool> checkIfEmailExists(String email) async {
    final task = await _auth.fetchSignInMethodsForEmail(email);
    return task.length == 1;
  }

  Future<bool> comfirmPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final provider = user.providerData.first.providerId;

      if (provider == 'password') {
        // Re-authenticate with password
        final credential = EmailAuthProvider.credential(
            email: user.email!, password: password);
        final credentialresult =
            await user.reauthenticateWithCredential(credential);
        return credentialresult.user != null;
      } else if (provider == 'google.com') {
        // Re-authenticate with Google
        final googleUser = await GoogleSignIn().signIn();
        final googleAuth = await googleUser?.authentication;
        if (googleAuth != null) {
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          final credentialresult =
              await user.reauthenticateWithCredential(credential);
          return credentialresult.user != null;
        } else {
          return false;
        }
      } else {
        print("Provider not supported for re-authentication");
        return false;
      }
    } on FirebaseException catch (e) {
      return false;
    }
  }

  Future<void> updateEmail(String email) async {
    final user = _auth.currentUser;
    try {
      return user?.verifyBeforeUpdateEmail(email);
    } on FirebaseException catch (e) {}
  }

  Future<void> updatePassword(String password) async {
    final user = _auth.currentUser;
    try {
      return user?.updatePassword(password);
    } on FirebaseException catch (e) {}
  }

  Future<void> updateName(String? name) async {
    final user = _auth.currentUser;
    try {
      return user?.updateDisplayName(name);
    } on FirebaseException catch (e) {}
  }

  Future<void> updatePhotoUrl(String? photo_url) async {
    final user = _auth.currentUser;
    try {
      return user?.updatePhotoURL(photo_url);
    } on FirebaseException catch (e) {}
  }

  Future<void> updatePhoneNumber(String phone) async {
    final user = _auth.currentUser;
    try {
      //user?.updatePhoneNumber(phone);
    } on FirebaseException catch (e) {}
  }
}
