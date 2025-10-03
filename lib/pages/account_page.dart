// lib/pages/account_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/pages/change_password_page.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/providers/auth_controller.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  /// Shows the styled dialog for logging out.
  void _showStyledLogoutDialog(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeProvider);
    // 2. GET LOCALIZATIONS FOR THE DIALOG
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          // 3. REPLACE ALL HARDCODED STRINGS
          title: Text(l10n.logout, style: TextStyle(fontWeight: FontWeight.bold, color: theme.secondary)),
          content: Text(l10n.logoutConfirmation, style: TextStyle(color: theme.inactive)),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel, style: TextStyle(color: theme.inactive.withOpacity(0.7))),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: theme.accent),
              child: Text(l10n.logout),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                        (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows the secure, styled dialog for account deletion.
  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeProvider);
    final passwordController = TextEditingController();
    // GET LOCALIZATIONS FOR THE DIALOG
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(builder: (context, ref, child) {
          final authState = ref.watch(authControllerProvider);
          return AlertDialog(
            backgroundColor: theme.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(l10n.deleteAccount, style: TextStyle(fontWeight: FontWeight.bold, color: theme.accent)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l10n.deleteAccountConfirmationBody, style: TextStyle(color: theme.inactive)),
              const SizedBox(height: 16),
              TextField(controller: passwordController, obscureText: true, style: TextStyle(color: theme.inactive), decoration: InputDecoration(labelText: l10n.currentPassword, labelStyle: TextStyle(color: theme.inactive))),
            ]),
            actions: [
              TextButton(child: Text(l10n.cancel, style: TextStyle(color: theme.inactive)), onPressed: () => Navigator.of(dialogContext).pop()),
              authState.isLoading
                  ? const CircularProgressIndicator()
                  : FilledButton(
                style: FilledButton.styleFrom(backgroundColor: theme.accent),
                child: Text(l10n.deletePermanently),
                onPressed: () async {
                  final success = await ref.read(authControllerProvider.notifier).deleteAccount(currentPassword: passwordController.text);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (!success && context.mounted) {
                    final error = ref.read(authControllerProvider).error ?? l10n.anUnknownErrorOccurred;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()), backgroundColor: theme.accent));
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  /// Shows a dialog to edit the user's display name.
  void _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName) {
    final theme = ref.read(themeProvider);
    final nameController = TextEditingController(text: currentName);
    // GET LOCALIZATIONS FOR THE DIALOG
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(l10n.editProfile, style: TextStyle(fontWeight: FontWeight.bold, color: theme.secondary)),
          content: TextField(
            controller: nameController,
            style: TextStyle(color: theme.inactive),
            decoration: InputDecoration(labelText: l10n.displayName, labelStyle: TextStyle(color: theme.inactive)),
          ),
          actions: [
            TextButton(child: Text(l10n.cancel, style: TextStyle(color: theme.inactive)), onPressed: () => Navigator.of(dialogContext).pop()),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: theme.secondary),
              child: Text(l10n.save),
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  await ref.read(userProfileNotifierProvider.notifier).updateDisplayName(newName);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final user = FirebaseAuth.instance.currentUser;
    final userProfileAsync = ref.watch(userProfileProvider);
    // GET LOCALIZATIONS FOR THE MAIN BUILD METHOD
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.primary,
      body: SafeArea(
        child: Container(
          color: theme.pageBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userProfileAsync.when(
                data: (profile) => _buildUserInfoHeader(
                  l10n: l10n,
                  theme: theme,
                  user: user,
                  displayName: profile?.displayName ?? user?.email?.split('@').first,
                ),
                loading: () => const Padding(padding: EdgeInsets.all(24.0), child: Center(child: CircularProgressIndicator())),
                error: (e, s) => Text(l10n.errorLoadingProfile, style: TextStyle(color: theme.accent)),
              ),
              Expanded(
                child: Center(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      _buildAccountCard(
                        icon: Icons.person_outline,
                        title: l10n.account, // <-- LOCALIZED
                        theme: theme,
                        children: [
                          _buildSubListItem(l10n.editProfile, context, l10n: l10n, theme: theme, onTap: () {
                            final currentName = userProfileAsync.value?.displayName ?? '';
                            _showEditProfileDialog(context, ref, currentName);
                          }),
                          _buildSubListItem(l10n.changePassword, context, l10n: l10n, theme: theme, onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
                          }),
                        ],
                      ),
                      _buildAccountCard(
                        icon: Icons.settings_outlined,
                        title: l10n.settings, // <-- LOCALIZED
                        theme: theme,
                        children: [
                          _buildSubListItem(l10n.notifications, context, l10n: l10n, theme: theme, onTap: () {}),
                          _buildSubListItem(l10n.theme, context, l10n: l10n, theme: theme, onTap: () {}),
                        ],
                      ),
                      _buildAccountCard(
                        icon: Icons.warning_amber_rounded,
                        title: l10n.dangerZone, // <-- LOCALIZED
                        theme: theme,
                        children: [
                          _buildSubListItem(l10n.deleteAccount, context, l10n: l10n, theme: theme, isDestructive: true, onTap: () => _showDeleteAccountDialog(context, ref)),
                        ],
                      ),
                      _buildAccountCard(
                        icon: Icons.star_border_purple500_sharp,
                        title: l10n.premium, // <-- LOCALIZED
                        theme: theme,
                        children: [
                          _buildSubListItem(l10n.manageSubscription, context, l10n: l10n, theme: theme, onTap: () {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  color: theme.background,
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 20, right: 16, top: 8, bottom: 8),
                    leading: Icon(Icons.logout, color: theme.accent, size: 28),
                    title: Text(l10n.logout, style: TextStyle(color: theme.secondary, fontSize: 18, fontWeight: FontWeight.bold)), // <-- LOCALIZED
                    onTap: () => _showStyledLogoutDialog(context, ref),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoHeader({required AppLocalizations l10n, required AppThemeData theme, required User? user, String? displayName}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(radius: 35, backgroundColor: theme.background, child: Icon(Icons.person_outline, size: 40, color: theme.secondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName ?? l10n.user, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.inactive), overflow: TextOverflow.ellipsis), // <-- LOCALIZED
                const SizedBox(height: 4),
                Text(user?.email ?? l10n.noEmailAvailable, style: TextStyle(fontSize: 14, color: theme.inactive.withOpacity(0.7)), overflow: TextOverflow.ellipsis), // <-- LOCALIZED
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard({required IconData icon, required String title, required List<Widget> children, required AppThemeData theme}) {
    // This widget now receives a localized title, no changes needed here.
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
        title: Text(title, style: TextStyle(color: theme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
        children: children,
      ),
    );
  }

  Widget _buildSubListItem(String title, BuildContext context, {required AppLocalizations l10n, required AppThemeData theme, required VoidCallback onTap, bool isDestructive = false}) {
    final color = isDestructive ? theme.accent : theme.inactive;
    // We can use the dynamic localization key here for the snackbar!
    final defaultOnTap = () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.featureNotImplemented(title))));
    return ListTile(
      title: Text(title, style: TextStyle(color: color)),
      contentPadding: const EdgeInsets.only(left: 72.0, right: 16.0, bottom: 8.0),
      // Use a real onTap if provided, otherwise use our placeholder.
      onTap: onTap,
    );
  }
}