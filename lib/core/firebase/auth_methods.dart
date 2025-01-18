import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthMethods {
  var myId = "";
  AuthMethods() {
    getCurrentUserId();
  }
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
      clientId:
          "182221656090-9phi32s2nujj8fk5dvcu36anp07u9sg8.apps.googleusercontent.com");

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
      return _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseException catch (e) {
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
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
      print("Error signing in with Google: $e");
      return null;
    }
  }

  bool get isPasswordAuthentication =>
      _auth.currentUser?.providerData.first.providerId == "password";

  Future<void> logOut() async {
    try {
      final provider = _auth.currentUser?.providerData.first.providerId;
      await _auth.signOut();
      // Sign out and disconnect Google account session
      if (!kIsWeb && Platform.isWindows) return;
      if (provider != null && provider.contains("google")) {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut(); // Sign out
          await _googleSignIn.disconnect(); // Disconnect the account
        }
      }
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
