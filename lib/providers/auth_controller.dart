import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// --- 1. IMPORT YOUR DATA PROVIDER TO INVALIDATE IT ---
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';

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
      // State is updated by the authStateChanges listener
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
      // State is updated by the authStateChanges listener
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
        // User cancelled the Google Sign-in
        state = AsyncValue.data(_auth.currentUser); // Reset to current state
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      // State is updated by the authStateChanges listener
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
      // Don't change the main auth state for this action
      print("Error sending password reset email: $e");
      return false;
    }
  }

  /// --- Change Password ---
  Future<void> changePassword(String newPassword) async {
    // This action shouldn't put the whole auth state into loading
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow; // Rethrow to be caught by the UI
    }
  }

  /// --- Delete Account ---
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        // State is updated by the authStateChanges listener to null
      }
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(e.message ?? 'Failed to delete account', StackTrace.current);
    }
  }

  /// --- Sign Out ---
  Future<void> signOut() async {
    try {
      // --- THE ROBUST FIX ---

      // 1. Explicitly reset the state of your main data controller.
      // This immediately puts it into a clean 'uninitialized' state.
      _ref.read(appDataProvider.notifier).reset();

      // 2. Invalidate all user-specific providers to dispose them and
      // force them to be recreated on next login.
      _ref.invalidate(appDataProvider);
      _ref.invalidate(userProfileProvider);
      _ref.invalidate(userProfileNotifierProvider);

      // 3. Sign out from the services.
      await _googleSignIn.signOut();
      await _auth.signOut();

    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}