// lib/providers/user_profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/models/user_profile.dart';
import 'package:sales_app_mvp/services/firestore_service.dart'; // Import FirestoreService

// This is your existing provider, it remains unchanged.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  print("--- UserProfileProvider Re-running ---");
  if (user != null) {
    print("User is logged in. UID: ${user.uid}");
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    return docRef.snapshots().map((snapshot) {
      print("Snapshot received for user ${user.uid}");

      if (snapshot.exists) {
        print("Document exists.");
        final data = snapshot.data();
        print("Raw Data from Firestore: $data");

        final userProfile = UserProfile.fromFirestore(data!, user.uid);
        print("Parsed UserProfile: isPremium = ${userProfile.isPremium}, displayName = ${userProfile.displayName}");

        return userProfile;
      } else {
        print("Document does NOT exist for UID: ${user.uid}");
        return null;
      }
    });
  }
  print("No user logged in.");
  return Stream.value(null);
});


// ========== NEW NOTIFIER ADDED BELOW ========== //

/// Notifier for handling user profile actions, like updating the display name.
final userProfileNotifierProvider =
StateNotifierProvider<UserProfileNotifier, AsyncValue<void>>((ref) {
  return UserProfileNotifier(ref);
});

class UserProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  UserProfileNotifier(this._ref) : super(const AsyncData(null));

  User? get _user => _ref.read(authStateChangesProvider).value;

  /// Updates the user's display name in both Firebase Auth and Firestore.
  Future<void> updateDisplayName(String newName) async {
    if (_user == null) throw Exception("Not logged in");
    state = const AsyncLoading();
    try {
      // 1. Update the display name in Firebase Auth
      await _user!.updateDisplayName(newName);

      // 2. Update the display name in the Firestore document via FirestoreService
      await _ref.read(firestoreServiceProvider).updateUserProfile({'displayName': newName});

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      // It's good practice to rethrow so the UI can catch it if needed
      rethrow;
    }
  }
}