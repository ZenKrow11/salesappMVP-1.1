// lib/providers/auth_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/settings_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final authControllerProvider =
StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthController(this._ref) : super(const AsyncValue.loading()) {
    _auth.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });
  }

  bool get isLoading => state.isLoading;
  Object? get error => state.hasError ? state.error : null;

  /// --- Email Sign In ---
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Login failed', StackTrace.current);
    }
  }

  /// --- Email Sign Up ---
  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      state =
          AsyncValue.error(e.message ?? 'Signup failed', StackTrace.current);
    }
  }

  /// --- Google Sign-In ---
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      // This implementation is correct for your dependency version.
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        state = AsyncValue.data(_auth.currentUser); // Cancelled by user
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(
        e.message ?? 'Google Sign-In failed',
        StackTrace.current,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// --- Password Reset ---
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print("Error sending password reset email: $e");
      return false;
    }
  }

  /// --- Change Password with Re-authentication ---
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    state = const AsyncValue.loading();
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      state = AsyncValue.error(
          "Not logged in or no email associated.", StackTrace.current);
      return;
    }

    try {
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      state = AsyncValue.data(user);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred.';
      if (e.code == 'wrong-password') {
        errorMessage = 'The current password you entered is incorrect.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The new password is too weak.';
      } else {
        errorMessage = e.message ?? 'Failed to change password.';
      }
      state = AsyncValue.error(errorMessage, StackTrace.current);
    }
  }

  /// --- Delete Account with Re-authentication (REFACTORED) ---
  Future<void> deleteAccount(String uid) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found to delete.');
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final userDocRef = firestore.collection('users').doc(uid);

      print('[AuthController] Starting full cascade delete for $uid ...');

      final knownSubcollections = [
        'favorites',
        'shopping_lists',
        'settings',
        'metadata',
        'customItems',
        'listedProductIds'
      ];

      for (final subcollection in knownSubcollections) {
        final subRef = userDocRef.collection(subcollection);
        final snapshot = await subRef.get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
        print('[AuthController] Deleted subcollection: $subcollection');
      }

      await userDocRef.delete().catchError((_) {
        print('[AuthController] No main user document found to delete.');
      });

      print('[AuthController] All Firestore user data deleted.');
      await user.delete();
      print('[AuthController] Firebase Auth account deleted.');

      // CORRECTED: Create a new instance before calling signOut.
      await GoogleSignIn().signOut();
      await _auth.signOut();

      final metadataBox = _ref.read(metadataBoxProvider);
      await metadataBox.clear();

      _ref.invalidate(appDataProvider);
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(userProfileNotifierProvider);
      _ref.invalidate(listedProductIdsProvider);
      _ref.invalidate(settingsProvider);
      _ref.invalidate(activeShoppingListProvider);

      print('[AuthController] Local data cleared and logout enforced.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
            'Reauthentication required before deleting this account.');
      } else {
        rethrow;
      }
    } catch (e) {
      print('[AuthController] Error during full cascade delete: $e');
      rethrow;
    }
  }

  /// --- Sign Out (REFACTORED) ---
  Future<void> signOut() async {
    try {
      // CORRECTED: Create a new instance before calling signOut.
      await GoogleSignIn().signOut();
      await _auth.signOut();

      final metadataBox = _ref.read(metadataBoxProvider);
      await metadataBox.clear();

      _ref.invalidate(appDataProvider);
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(userProfileNotifierProvider);
      _ref.invalidate(listedProductIdsProvider);
      _ref.invalidate(settingsProvider);
      _ref.invalidate(activeShoppingListProvider);

    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}