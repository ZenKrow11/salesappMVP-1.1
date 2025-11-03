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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- THIS IS THE FIX ---
  // The listener now correctly updates the state when the auth status changes.
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
      // On success, the authStateChanges listener above will handle setting the data state.
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
      // On success, the authStateChanges listener will handle it.
    } on FirebaseAuthException catch (e) {
      state =
          AsyncValue.error(e.message ?? 'Signup failed', StackTrace.current);
    }
  }

  /// --- Google Sign-In ---
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = AsyncValue.data(_auth.currentUser); // User cancelled the flow
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      // On success, the authStateChanges listener will handle it.
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(
          e.message ?? 'Google Sign-In failed', StackTrace.current);
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
      state = AsyncValue.data(user); // Success, return to a stable state
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

  /// --- Delete Account with Re-authentication ---
  Future<void> deleteAccount(String uid) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found to delete.');
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final userDocRef = firestore.collection('users').doc(uid);

      print('[AuthController] Starting full cascade delete for $uid ...');

      // --- Delete known subcollections (works for all Firestore versions) ---
      final knownSubcollections = [
        'favorites',
        'shopping_lists',
        'settings',
        'metadata',
        // add more if you introduce new ones later
      ];

      for (final subcollection in knownSubcollections) {
        final subRef = userDocRef.collection(subcollection);
        final snapshot = await subRef.get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
        print('[AuthController] Deleted subcollection: $subcollection');
      }

      // --- Delete the main user document ---
      await userDocRef.delete().catchError((_) {
        print('[AuthController] No main user document found to delete.');
      });

      print('[AuthController] All Firestore user data deleted.');

      // --- Delete Firebase Authentication account ---
      await user.delete();
      print('[AuthController] Firebase Auth account deleted.');

      // --- Force logout and local cleanup ---
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Clear Hive boxes and Riverpod state
      final metadataBox = _ref.read(metadataBoxProvider);
      await metadataBox.clear();

      _ref.invalidate(appDataProvider);
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(userProfileNotifierProvider);
      _ref.invalidate(listedProductIdsProvider);
      _ref.invalidate(settingsProvider);
      _ref.invalidate(activeShoppingListProvider);

      await _ref
          .read(activeShoppingListProvider.notifier)
          .setActiveList(kDefaultListName);

      print('[AuthController] Local data cleared and logout enforced.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Reauthentication required before deleting this account.');
      } else {
        rethrow;
      }
    } catch (e) {
      print('[AuthController] Error during full cascade delete: $e');
      rethrow;
    }
  }



  /// --- Sign Out ---
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      // On success, the authStateChanges listener will fire with `null`.

      // Clear local storage and reset providers
      final metadataBox = _ref.read(metadataBoxProvider);
      await metadataBox.clear();
      _ref.read(appDataProvider.notifier).reset();
      _ref.invalidate(appDataProvider);
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(userProfileNotifierProvider);
      _ref.invalidate(listedProductIdsProvider);
      _ref.invalidate(settingsProvider);
      await _ref.read(activeShoppingListProvider.notifier).setActiveList(kDefaultListName);

    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}