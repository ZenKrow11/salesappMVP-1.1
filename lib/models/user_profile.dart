// lib/models/user_profile.dart

class UserProfile {
  final String uid;
  final String email;
  final String displayName; // NEW: Add the display name field
  final bool isPremium;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName, // NEW: Add to constructor
    this.isPremium = false,
  });

  // A method to create a UserProfile from a Firestore document
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      // NEW: Read the display name, with a fallback if it doesn't exist
      displayName: data['displayName'] ?? data['email']?.split('@').first ?? 'User',
      isPremium: data['isPremium'] ?? false,
    );
  }
}