// lib/providers/auth_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authControllerProvider =
NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // THIS IS THE CORRECT WAY TO INITIALIZE
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  // ... (Your signInWithEmail and signUpWithEmail methods are here) ...
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(e.message ?? 'An unknown error occurred', st);
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      state = const AsyncData(null);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(e.message ?? 'An unknown error occurred', st);
      rethrow;
    }
  }


  // --- REPLACE YOUR signInWithGoogle METHOD WITH THIS ---
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      // The authenticate() method now directly returns the signed-in account
      // or null if the user cancelled.
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        state = const AsyncData(null); // User cancelled the sign-in
        return;
      }

      // The rest of the flow is the same as before
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}