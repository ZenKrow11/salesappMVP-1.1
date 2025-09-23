// lib/providers/user_profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Make sure you import main.dart to get access to the new provider
import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/models/user_profile.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authValidationProvider);
  final user = authState.value;
  print("--- UserProfileProvider Re-running ---");
  if (user != null) {
    print("User is logged in. UID: ${user.uid}");
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // VVVV --- THIS IS THE KEY CHANGE --- VVVV
    return docRef.snapshots().distinct((prev, next) => prev.data() == next.data()).map((snapshot) {
      // ^^^^ ----------------------------- ^^^^
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

final userProfileNotifierProvider =
StateNotifierProvider<UserProfileNotifier, AsyncValue<void>>((ref) {
  return UserProfileNotifier(ref);
});

class UserProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  UserProfileNotifier(this._ref) : super(const AsyncData(null));

  // FIXED: Reading the new validation provider
  User? get _user => _ref.read(authValidationProvider).value;

  Future<void> updateDisplayName(String newName) async {
    if (_user == null) throw Exception("Not logged in");
    state = const AsyncLoading();
    try {
      await _user!.updateDisplayName(newName);
      await _ref.read(firestoreServiceProvider).updateUserProfile({'displayName': newName});
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}