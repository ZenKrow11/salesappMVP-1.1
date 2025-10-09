// lib/providers/user_profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/models/user_profile.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';

// -----------------------------------------------------------------------------
//   1. Main Profile Data Provider
// -----------------------------------------------------------------------------

/// Streams the complete [UserProfile] object from Firestore.
/// This is the single source of truth for the current user's data.
/// It automatically updates whenever the data changes in the database.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  // Watches for changes in authentication state (login/logout).
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user != null) {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // Return a stream of the user's document.
    return docRef.snapshots().map((snapshot) {
      if (snapshot.exists) {
        // If the document exists, parse it into a UserProfile object.
        // This now includes parsing the 'isPremium' field thanks to the updated model.
        return UserProfile.fromFirestore(snapshot.data()!, user.uid);
      } else {
        // If the document doesn't exist, the user is logged in but has no profile data.
        return null;
      }
    });
  }
  // If no user is logged in, return a stream with a null value.
  return Stream.value(null);
});


// -----------------------------------------------------------------------------
//   2. Derived Provider for UI (The Feature Gate)
// -----------------------------------------------------------------------------

/// A simple provider that returns `true` if the user is a premium subscriber.
///
/// It derives its state from the main [userProfileProvider] and provides
/// a safe default of `false` during loading, errors, or if the user is logged out.
/// This is the provider you should use throughout your UI for feature gating.
final isPremiumProvider = Provider<bool>((ref) {
  final userProfileAsync = ref.watch(userProfileProvider);

  // Use .when for robust handling of all possible states.
  return userProfileAsync.when(
    data: (profile) => profile?.isPremium ?? false, // If profile exists, use its status, else false.
    loading: () => false, // Default to NOT premium while profile is loading.
    error: (err, stack) => false, // Default to NOT premium if an error occurs.
  );
});


// -----------------------------------------------------------------------------
//   3. Notifier for Profile Actions/Mutations
// -----------------------------------------------------------------------------

/// Provider for the notifier that handles user profile actions.
final userProfileNotifierProvider =
StateNotifierProvider<UserProfileNotifier, AsyncValue<void>>((ref) {
  return UserProfileNotifier(ref);
});

/// Notifier for handling user profile actions, like updating data in Firestore.
class UserProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  UserProfileNotifier(this._ref) : super(const AsyncData(null));

  // A helper to get the current Firebase user.
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
      rethrow; // Rethrow so the UI can catch it if needed
    }
  }

  /// **[NEW]** Updates the user's premium status in Firestore.
  /// This should be called after a successful in-app purchase is verified.
  Future<void> updateUserPremiumStatus(bool newStatus) async {
    if (_user == null) throw Exception("Not logged in");
    state = const AsyncLoading();
    try {
      // Update the 'isPremium' field in the Firestore document.
      await _ref.read(firestoreServiceProvider).updateUserProfile({'isPremium': newStatus});
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}