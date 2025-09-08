// lib/providers/user_profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/models/user_profile.dart';
// This provider will give us the current user's profile data
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  // Watch the auth state
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  // --- START OF DEBUGGING CODE ---
  print("--- UserProfileProvider Re-running ---");
  if (user != null) {
    print("User is logged in. UID: ${user.uid}");
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    return docRef.snapshots().map((snapshot) {
      print("Snapshot received for user ${user.uid}");

      if (snapshot.exists) {
        print("Document exists.");
        final data = snapshot.data();
        print("Raw Data from Firestore: $data"); // This is the most important line

        final userProfile = UserProfile.fromFirestore(data!, user.uid);
        print("Parsed UserProfile: isPremium = ${userProfile.isPremium}");

        return userProfile;
      } else {
        print("Document does NOT exist for UID: ${user.uid}");
        return null;
      }
    });
  }
  print("No user logged in.");
  // If no user is logged in, provide null
  return Stream.value(null);
  // --- END OF DEBUGGING CODE ---
});
