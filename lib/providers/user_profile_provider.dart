// lib/providers/user_profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sales_app_mvp/main.dart'; // For authStateChangesProvider
import 'package:sales_app_mvp/models/user_profile.dart';

// This provider will give us the current user's profile data
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  // Watch the auth state
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  if (user != null) {
    // If the user is logged in, listen to their document in Firestore
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    return docRef.snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserProfile.fromFirestore(snapshot.data()!, user.uid);
      }
      return null; // Or a default UserProfile
    });
  }

  // If no user is logged in, provide null
  return Stream.value(null);
});