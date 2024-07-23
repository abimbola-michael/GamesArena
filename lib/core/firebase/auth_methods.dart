import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthMethods {
  var myId = "";
  AuthMethods() {
    getCurrentUserId();
  }
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<UserCredential?> createAccount(String email, String password) async {
    try {
      return auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseException catch (e) {
      return null;
    }
  }

  Future<UserCredential?> login(String email, String password) async {
    try {
      return auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseException catch (e) {
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (!kIsWeb && Platform.isWindows) return null;
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken, idToken: googleAuth?.idToken);
      final UserCredential userCredential =
          await auth.signInWithCredential(credential);
      return userCredential;
    } on FirebaseException catch (e) {
      return null;
    }
  }

  void addUser() {}

  Future<void> logOut() async {
    try {
      return auth.signOut();
    } on FirebaseException catch (e) {}
  }

  Future<void> sendEmailVerification() async {
    final user = auth.currentUser;
    try {
      return user?.sendEmailVerification();
    } on FirebaseException catch (e) {}
  }

  Future<bool> isEmailVerified() async {
    final user = auth.currentUser;
    return user?.emailVerified ?? false;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      return auth.sendPasswordResetEmail(email: email);
    } on FirebaseException catch (e) {}
  }

  String getCurrentUserId() {
    myId = auth.currentUser?.uid ?? "";
    return myId;
  }

  Future<void> deleteAccount() async {
    final user = auth.currentUser;
    try {
      return user?.delete();
    } on FirebaseException catch (e) {}
  }

  Future<bool> checkIfEmailExists(String email) async {
    final task = await auth.fetchSignInMethodsForEmail(email);
    return task.length == 1;
  }

  Future<bool> comfirmPassword(String password) async {
    final user = auth.currentUser;
    if (user == null) return false;
    try {
      final credential =
          EmailAuthProvider.credential(email: user.email!, password: password);
      final credentialresult =
          await user.reauthenticateWithCredential(credential);
      return credentialresult.user != null;
    } on FirebaseException catch (e) {
      return false;
    }
  }

  Future<void> updateEmail(String email) async {
    final user = auth.currentUser;
    try {
      return user?.verifyBeforeUpdateEmail(email);
    } on FirebaseException catch (e) {}
  }

  Future<void> updatePassword(String password) async {
    final user = auth.currentUser;
    try {
      return user?.updatePassword(password);
    } on FirebaseException catch (e) {}
  }

  Future<void> updateName(String? name) async {
    final user = auth.currentUser;
    try {
      return user?.updateDisplayName(name);
    } on FirebaseException catch (e) {}
  }

  Future<void> updatePhotoUrl(String? photo_url) async {
    final user = auth.currentUser;
    try {
      return user?.updatePhotoURL(photo_url);
    } on FirebaseException catch (e) {}
  }

  Future<void> updatePhoneNumber(String phone) async {
    final user = auth.currentUser;
    try {
      //user?.updatePhoneNumber(phone);
    } on FirebaseException catch (e) {}
  }
}
