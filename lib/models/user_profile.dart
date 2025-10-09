// lib/models/user_profile.dart

class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final bool isPremium; // <-- ADD THIS LINE

  UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.isPremium = false, // <-- ADD THIS and provide a default
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      // Safely parse the 'isPremium' field. Default to false if it doesn't exist.
      isPremium: data['isPremium'] as bool? ?? false, // <-- ADD THIS LINE
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'isPremium': isPremium, // <-- ADD THIS LINE
    };
  }
}