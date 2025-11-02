// lib/providers/auth_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/settings_provider.dart';

final authControllerProvider =
StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
      state = AsyncValue.error(e.message ?? 'Signup failed', StackTrace.current);
    }
  }

  /// --- Google Sign-In ---
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = AsyncValue.data(_auth.currentUser);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Google Sign-In failed', StackTrace.current);
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

  /// --- Change Password ---
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception("Not logged in");
      }
    } catch (e) {
      // Don't change the main auth state, but rethrow to the UI.
      rethrow;
    }
  }

  /// --- Delete Account ---
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Failed to delete account', StackTrace.current);
    }
  }

  /// --- Sign Out ---
  Future<void> signOut() async {
    try {
      // Clear local storage
      final metadataBox = _ref.read(metadataBoxProvider);
      await metadataBox.clear();

      // Reset all in-memory user-specific state
      _ref.read(appDataProvider.notifier).reset();
      _ref.invalidate(appDataProvider);
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(userProfileNotifierProvider);
      _ref.invalidate(listedProductIdsProvider);

      // --- THIS IS THE FIX ---
      // Explicitly invalidate the settings provider. This will force it to be
      // destroyed and recreated on the next login, triggering _loadSettings() again.
      _ref.invalidate(settingsProvider);
      // --- END OF FIX ---

      // Reset the active list to default in SharedPreferences
      await _ref.read(activeShoppingListProvider.notifier).setActiveList(kDefaultListName);

      // Sign out from the services
      await _googleSignIn.signOut();
      await _auth.signOut();

    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}