import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authControllerProvider =
NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  AsyncValue<void> build() => const AsyncData(null);

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

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      // Initialize GoogleSignIn singleton
      await GoogleSignIn.instance.initialize(
        serverClientId: '307296886319-48mgnkuihjsvdu9ssetrl4vellreek09.apps.googleusercontent.com',
      );

      // Listen for the next sign-in event only
      final event = await GoogleSignIn.instance.authenticationEvents
          .where((event) => event is GoogleSignInAuthenticationEventSignIn)
          .first as GoogleSignInAuthenticationEventSignIn;

      final googleUser = event.user;
      final googleAuth = googleUser.authentication;

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

  Future<void> startGoogleSignInFlow() async {
    // Call this method from your UI to trigger the Google sign-in process
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      await GoogleSignIn.instance.authenticate();
    } else {
      // For platforms that don't support authenticate(), use platform-specific flow
      // (e.g., web: use the Google button widget)
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
