import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // Helper method to create an ExpansionTile with consistent styling
  Widget _buildExpansionTile({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: AppColors.active, size: 40),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 24,
        ),
      ),
      children: children,
    );
  }

  // Helper method for the placeholder content inside expandable tiles
  Widget _buildSubListItem(String title) {
    return ListTile(
      title: Text(title),
      contentPadding: const EdgeInsets.only(left: 30.0),
      onTap: () {
        // Placeholder for future functionality
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
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
        children: [
          // User Info Header
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.account_circle,
                      size: 80, color: AppColors.secondary),
                  const SizedBox(height: 8),
                  Text(
                    'Logged in as',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    user.email ?? 'No email available',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          const Divider(),

          // Account (Expandable)
          _buildExpansionTile(
            icon: Icons.person,
            title: 'Account',
            children: [
              _buildSubListItem('Edit Profile'),
              _buildSubListItem('Change Password'),
              _buildSubListItem('My Details'),
            ],
          ),

          // Settings (Expandable)
          _buildExpansionTile(
            icon: Icons.settings,
            title: 'Settings',
            children: [
              _buildSubListItem('Notifications'),
              _buildSubListItem('Theme'),
              _buildSubListItem('Language'),
            ],
          ),

          // Contact (Expandable)
          _buildExpansionTile(
            icon: Icons.help_outline,
            title: 'Contact',
            children: [
              _buildSubListItem('Help & FAQ'),
              _buildSubListItem('Report an Issue'),
            ],
          ),

          const Divider(),

          // Logout Button (Not expandable)
          ListTile(
            leading:
            const Icon(Icons.logout, color: AppColors.active, size: 40),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 24,
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
                        child: const Text('Logout'),
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
        ],
      ),
    );
  }
}