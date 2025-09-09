// lib/providers/auth_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

final authControllerProvider =
StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController();
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController() : super(const AsyncData(null));

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _createUserProfileDocument(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    await userRef.set({
      'email': user.email,
      'isPremium': false,
      'displayName': user.displayName ?? user.email?.split('@').first,
    });
  }

  // ========== NEW METHODS ADDED HERE ==========

  /// Re-authenticates the user and then changes their password.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncLoading();
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) throw Exception('No user is currently signed in.');

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);

      state = const AsyncData(null);
      return true;
    } on FirebaseAuthException catch (e, st) {
      debugPrint('CHANGE PASSWORD ERROR: [${e.code}] ${e.message}');
      state = AsyncError(e.message ?? 'An unknown error occurred', st);
      return false;
    }
  }

  /// Re-authenticates and then permanently deletes the user's account and data.
  Future<bool> deleteAccount({required String currentPassword}) async {
    state = const AsyncLoading();
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) throw Exception('No user is currently signed in.');

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(cred);

      // Important: Delete Firestore data BEFORE deleting the auth user.
      // Note: This simple delete won't remove subcollections. A Cloud Function
      // is the production-ready solution for cascading deletes.
      await _firestore.collection('users').doc(user.uid).delete();

      await user.delete();

      state = const AsyncData(null);
      return true;
    } on FirebaseAuthException catch (e, st) {
      debugPrint('DELETE ACCOUNT ERROR: [${e.code}] ${e.message}');
      state = AsyncError(e.message ?? 'An unknown error occurred', st);
      return false;
    }
  }

  // ==========================================

  Future<bool> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      state = const AsyncData(null);
      return true;
    } on FirebaseAuthException catch (e, st) {
      debugPrint('SIGN IN ERROR: [${e.code}] ${e.message}');
      state = AsyncError(e.message ?? 'An unknown error occurred', st);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      final userCredential =
      await _auth.createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await _createUserProfileDocument(userCredential.user!);
      }

      state = const AsyncData(null);
      return true;
    } on FirebaseAuthException catch (e, st) {
      debugPrint('SIGN UP ERROR: [${e.code}] ${e.message}');
      state = AsyncError(e.message ?? 'An unknown error occurred', st);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = const AsyncData(null);
        return false;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.additionalUserInfo?.isNewUser == true &&
          userCredential.user != null) {
        await _createUserProfileDocument(userCredential.user!);
      }

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}