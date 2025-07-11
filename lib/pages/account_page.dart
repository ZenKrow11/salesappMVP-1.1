import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // Helper method to create an expandable Card with consistent styling
  Widget _buildAccountCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: AppColors.primary,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
        shape: const Border(), // Remove the default border when expanded
        collapsedShape: const Border(), // Remove the default border when collapsed
        collapsedBackgroundColor: AppColors.primary,
        iconColor: AppColors.secondary,
        collapsedIconColor: AppColors.secondary,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: AppColors.secondary, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: children,
      ),
    );
  }

  // Helper method for the content inside expandable tiles
  Widget _buildSubListItem(String title, BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: AppColors.active)),
      contentPadding: const EdgeInsets.only(left: 72.0, right: 16.0), // Align with title
      onTap: () {
        // Placeholder for future functionality
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title feature is not yet implemented.'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user to display their email
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        children: [
          // Page Header
          const Center(
            child: Text('My Account',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary)),
          ),
          // Removed Divider
          // const Divider(height: 24, indent: 20, endIndent: 20),
          const SizedBox(height: 10), // Added SizedBox for spacing

          // User Info Header
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                children: [
                  const Icon(Icons.account_circle,
                      size: 60, color: AppColors.secondary),
                  const SizedBox(height: 8),
                  Text(
                    'Logged in as',
                    style: TextStyle(color: AppColors.inactive, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? 'No email available',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.active),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // Account (Expandable)
          _buildAccountCard(
            icon: Icons.person_outline,
            title: 'Account',
            children: [
              _buildSubListItem('Edit Profile', context),
              _buildSubListItem('Change Password', context),
              _buildSubListItem('My Details', context),
            ],
          ),

          // Settings (Expandable)
          _buildAccountCard(
            icon: Icons.settings_outlined,
            title: 'Settings',
            children: [
              _buildSubListItem('Notifications', context),
              _buildSubListItem('Theme', context),
              _buildSubListItem('Language', context),
            ],
          ),

          // Contact (Expandable)
          _buildAccountCard(
            icon: Icons.help_outline,
            title: 'Contact',
            children: [
              _buildSubListItem('Help & FAQ', context),
              _buildSubListItem('Report an Issue', context),
            ],
          ),

          const SizedBox(height: 20),

          // Logout Button (Not expandable, styled as a distinct Card)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            color: AppColors.primary,
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: const Icon(Icons.logout, color: AppColors.accent, size: 28),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                // Show a confirmation dialog before logging out
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(); // Close the dialog
                          },
                        ),
                        TextButton(
                          child: const Text('Logout', style: TextStyle(color: AppColors.accent)),
                          onPressed: () async {
                            // Close the dialog first
                            Navigator.of(dialogContext).pop();

                            // Perform the sign out
                            await FirebaseAuth.instance.signOut();

                            // Navigate to login screen and remove all previous routes
                            // This prevents the user from pressing 'back' to get into the app.
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login', (Route<dynamic> route) => false);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}