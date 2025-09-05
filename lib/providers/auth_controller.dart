// lib/providers/auth_controller.dart

// NEW: Import Cloud Firestore to interact with the database.
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
  // NEW: Add a reference to the Firestore instance.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // NEW: Helper method to create a user profile document in Firestore.
  // This will be called right after a new user is created.
  Future<void> _createUserProfileDocument(User user) async {
    // Reference to the new user's document using their unique UID.
    final userRef = _firestore.collection('users').doc(user.uid);

    // Set the initial data for the new user.
    // This is where you set 'isPremium' to false by default.
    await userRef.set({
      'email': user.email,
      'isPremium': false,
      // You can add other initial fields here, like a creation timestamp.
    });
  }

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
      // 1. Create the user with Firebase Auth.
      final userCredential =
      await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // 2. NEW: After successful auth creation, create their Firestore document.
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
        // User canceled the sign-in
        state = const AsyncData(null);
        return false;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 1. Sign in to Firebase with the Google credentials.
      final userCredential = await _auth.signInWithCredential(credential);

      // 2. NEW: Check if this is a new user. If so, create their Firestore document.
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