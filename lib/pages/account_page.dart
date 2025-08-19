import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/providers/auth_controller.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  // Helper method to create an expandable Card with consistent styling
  Widget _buildAccountCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required AppThemeData theme,
  }) {
    // UPDATED: Card styling now matches new cohesive design
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: theme.background, // UPDATED
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        backgroundColor: theme.background,
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: theme.secondary, // UPDATED
        collapsedIconColor: theme.secondary, // UPDATED
        tilePadding: const EdgeInsets.only(left: 20, right: 16, top: 8, bottom: 8),
        leading: Icon(icon, color: theme.secondary, size: 28), // UPDATED
        title: Text(
          title,
          style: TextStyle(
            color: theme.secondary, // UPDATED
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: children,
      ),
    );
  }

  // Helper method for the content inside expandable tiles
  Widget _buildSubListItem(
      String title,
      BuildContext context, {
        required AppThemeData theme,
      }) {
    return ListTile(
      title: Text(title, style: TextStyle(color: theme.inactive)),
      contentPadding: const EdgeInsets.only(left: 72.0, right: 16.0, bottom: 8.0),
      onTap: () {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: theme.pageBackground, // Correctly using the designated page background
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
            child: Text('My Account',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.secondary)),
          ),
          const SizedBox(height: 10),

          // User Info Header
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                children: [
                  Icon(Icons.account_circle,
                      size: 60, color: theme.secondary),
                  const SizedBox(height: 8),
                  Text(
                    'Logged in as',
                    style: TextStyle(color: theme.inactive.withOpacity(0.7), fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? 'No email available',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.inactive),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // Account (Expandable)
          _buildAccountCard(
            icon: Icons.person_outline,
            title: 'Account',
            theme: theme,
            children: [
              _buildSubListItem('Edit Profile', context, theme: theme),
              _buildSubListItem('Change Password', context, theme: theme),
              _buildSubListItem('My Details', context, theme: theme),
            ],
          ),

          // Settings (Expandable)
          _buildAccountCard(
            icon: Icons.settings_outlined,
            title: 'Settings',
            theme: theme,
            children: [
              _buildSubListItem('Notifications', context, theme: theme),
              _buildSubListItem('Theme', context, theme: theme),
              _buildSubListItem('Language', context, theme: theme),
            ],
          ),

          // Contact (Expandable)
          _buildAccountCard(
            icon: Icons.help_outline,
            title: 'Contact',
            theme: theme,
            children: [
              _buildSubListItem('Help & FAQ', context, theme: theme),
              _buildSubListItem('Report an Issue', context, theme: theme),
            ],
          ),

          const SizedBox(height: 20),

          // Logout Button
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            color: theme.background, // UPDATED
            child: ListTile(
              contentPadding:
              const EdgeInsets.only(left: 20, right: 16, top: 8, bottom: 8),
              leading: Icon(Icons.logout, color: theme.accent, size: 28),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: theme.secondary, // UPDATED
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
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
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        TextButton(
                          child: Text('Logout', style: TextStyle(color: theme.accent)),
                          onPressed: () async {
                            Navigator.of(dialogContext).pop(); // Close the dialog first
                            // Use the AuthController to sign out from all services
                            await ref.read(authControllerProvider.notifier).signOut();
                            // Navigate back to the login screen after signing out
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