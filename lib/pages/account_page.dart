// lib/pages/account_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/providers/auth_controller.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: theme.primary,
      body: SafeArea(
        child: Container(
          color: theme.pageBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOP SECTION: User Info Header ---
              _buildUserInfoHeader(theme: theme, user: user),

              // --- MIDDLE SECTION: Scrollable Cards ---
              Expanded(
                // --- UPDATED: Added Center to vertically align the ListView ---
                child: Center(
                  child: ListView(
                    // --- UPDATED: shrinkWrap is essential for Center to work ---
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
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
                      _buildAccountCard(
                        icon: Icons.help_outline,
                        title: 'Contact',
                        theme: theme,
                        children: [
                          _buildSubListItem('Help & FAQ', context, theme: theme),
                          _buildSubListItem('Report an Issue', context, theme: theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // --- BOTTOM SECTION: Logout Button (Fixed at the bottom) ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  color: theme.background,
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.only(left: 20, right: 16, top: 8, bottom: 8),
                    leading: Icon(Icons.logout, color: theme.accent, size: 28),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        color: theme.secondary,
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
                                onPressed: () => Navigator.of(dialogContext).pop(),
                              ),
                              TextButton(
                                child: Text('Logout', style: TextStyle(color: theme.accent)),
                                onPressed: () async {
                                  Navigator.of(dialogContext).pop();
                                  await ref.read(authControllerProvider.notifier).signOut();
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoHeader({required AppThemeData theme, required User? user}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Row(
        // --- UPDATED: Vertically centers the text next to the icon ---
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 35,
            backgroundColor: theme.background,
            child: Icon(
              Icons.person_outline,
              size: 40,
              color: theme.secondary,
            ),
          ),
          const SizedBox(width: 16),
          // User Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logged in as',
                  style: TextStyle(
                    color: theme.inactive.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'No email available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.inactive,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create an expandable Card with consistent styling
  Widget _buildAccountCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required AppThemeData theme,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: theme.background,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        backgroundColor: theme.background,
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: theme.secondary,
        collapsedIconColor: theme.secondary,
        tilePadding: const EdgeInsets.only(left: 20, right: 16, top: 8, bottom: 8),
        leading: Icon(icon, color: theme.secondary, size: 28),
        title: Text(
          title,
          style: TextStyle(
            color: theme.secondary,
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
}