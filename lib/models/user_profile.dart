// lib/models/user_profile.dart
class UserProfile {
  final String uid;
  final String email;
  final bool isPremium;

  UserProfile({required this.uid, required this.email, this.isPremium = false});

  // A method to create a UserProfile from a Firestore document
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      isPremium: data['isPremium'] ?? false,
    );
  }
}