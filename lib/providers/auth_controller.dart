// lib/providers/auth_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// This provider will give us access to the AuthController instance.
final authControllerProvider =
StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController();
});

class AuthController extends StateNotifier<bool> {
  // The initial state is 'false' (not loading).
  AuthController() : super(false);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signInWithEmail(String email, String password) async {
    state = true; // Set state to loading
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // On success, AuthGate will automatically handle navigation.
    } catch (e) {
      // If an error occurs, re-throw it so the UI can catch it and show a SnackBar.
      rethrow;
    } finally {
      state = false; // Set state back to not loading
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = true;
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> signInWithGoogle() async {
    state = true;
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = false; // User cancelled the sign-in
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    } finally {
      // Don't set state to false here if a user was successfully selected,
      // as the app will be navigating away. Only set it if there's an error,
      // which is handled by the `try-catch-rethrow`.
      // If we always set it to false, there can be a flicker.
      if (mounted) { // 'mounted' is a property of StateNotifier
        state = false;
      }
    }
  }
}