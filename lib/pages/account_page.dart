import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ADDED
import 'package:sales_app_mvp/widgets/app_theme.dart'; // UPDATED

// UPDATED to ConsumerWidget to access theme via ref
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  // Helper method to create an expandable Card with consistent styling
  Widget _buildAccountCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required AppThemeData theme, // ADDED theme parameter
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: theme.primary, // UPDATED
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        backgroundColor: theme.secondary.withOpacity(0.1), // UPDATED & FIXED
        shape: const Border(),
        collapsedShape: const Border(),
        collapsedBackgroundColor: theme.primary, // UPDATED
        iconColor: theme.secondary, // UPDATED
        collapsedIconColor: theme.secondary, // UPDATED
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
        required AppThemeData theme, // ADDED theme parameter
      }) {
    return ListTile(
      title: Text(title, style: TextStyle(color: theme.secondary)), // UPDATED (was active)
      contentPadding: const EdgeInsets.only(left: 72.0, right: 16.0),
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
  Widget build(BuildContext context, WidgetRef ref) { // UPDATED to include WidgetRef
    final theme = ref.watch(themeProvider); // Get theme from provider
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: theme.pageBackground, // UPDATED
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        children: [
          // Page Header
          Center(
            child: Text('My Account',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.secondary)), // UPDATED
          ),
          const SizedBox(height: 10),

          // User Info Header
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                children: [
                  Icon(Icons.account_circle,
                      size: 60, color: theme.secondary), // UPDATED
                  const SizedBox(height: 8),
                  Text(
                    'Logged in as',
                    style: TextStyle(color: theme.inactive, fontSize: 14), // UPDATED
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? 'No email available',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.secondary), // UPDATED (was active)
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // Account (Expandable)
          _buildAccountCard(
            icon: Icons.person_outline,
            title: 'Account',
            theme: theme, // Pass theme
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
            theme: theme, // Pass theme
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
            theme: theme, // Pass theme
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
            color: theme.primary, // UPDATED
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Icon(Icons.logout, color: theme.accent, size: 28), // UPDATED
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
                          child: Text('Logout', style: TextStyle(color: theme.accent)), // UPDATED
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await FirebaseAuth.instance.signOut();
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