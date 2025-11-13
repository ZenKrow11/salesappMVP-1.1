// lib/pages/account_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/pages/change_password_page.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/providers/auth_controller.dart';
import 'package:sales_app_mvp/components/upgrade_dialog.dart';
import 'package:sales_app_mvp/providers/auth_wrapper.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  // Logout dialog
  void _showStyledLogoutDialog(BuildContext context, WidgetRef ref) {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(l10n.logout, style: TextStyle(fontWeight: FontWeight.bold, color: theme.secondary)),
        content: Text(l10n.logoutConfirmation, style: TextStyle(color: theme.inactive)),
        actions: [
          TextButton(
            // --- FIX: Replaced deprecated withOpacity with withAlpha ---
            child: Text(l10n.cancel, style: TextStyle(color: theme.inactive.withAlpha((255 * 0.7).round()))),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.accent),
            child: Text(l10n.logout),
            onPressed: () async {
              // Note: context.mounted check is crucial here
              if (!context.mounted) return;
              Navigator.of(dialogContext).pop();
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                      (_) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Confirm account delete dialog - no password required
  Future<void> _showConfirmDeleteDialog(BuildContext context, WidgetRef ref) async {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(l10n.deleteAccount, style: TextStyle(fontWeight: FontWeight.bold, color: theme.accent)),
        content: Text(l10n.deleteAccountConfirmationBody, style: TextStyle(color: theme.inactive)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel, style: TextStyle(color: theme.inactive)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.accent),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deletePermanently),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    // --- FIX: Check context before async operation ---
    if (!context.mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await ref.read(authControllerProvider.notifier).deleteAccount(user.uid);
      }
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
              (_) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: ${e.toString()}'), backgroundColor: theme.accent),
        );
      }
    }
  }

  // Edit profile dialog
  void _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName) {
    final theme = ref.read(themeProvider);
    final nameController = TextEditingController(text: currentName);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(l10n.editProfile, style: TextStyle(fontWeight: FontWeight.bold, color: theme.secondary)),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: theme.inactive),
          decoration: InputDecoration(
            labelText: l10n.displayName,
            labelStyle: TextStyle(color: theme.inactive),
          ),
        ),
        actions: [
          TextButton(
            child: Text(l10n.cancel, style: TextStyle(color: theme.inactive)),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.secondary),
            child: Text(l10n.save),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                // No context used after await, so no check needed here.
                await ref.read(userProfileNotifierProvider.notifier).updateDisplayName(newName);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  // Manage subscription placeholder
  void _manageSubscription(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.featureNotImplemented(l10n.manageSubscription))),
    );
  }

  // Build UI
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final user = FirebaseAuth.instance.currentUser;
    final userProfileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context)!;
    final isPremium = userProfileAsync.value?.isPremium ?? false;

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
                  context: context,
                  ref: ref,
                  l10n: l10n,
                  theme: theme,
                  user: user,
                  displayName: profile?.displayName ?? user?.email?.split('@').first,
                  isPremium: profile?.isPremium ?? false,
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, s) => Text(l10n.errorLoadingProfile, style: TextStyle(color: theme.accent)),
              ),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    _buildAccountCard(
                      icon: Icons.person_outline,
                      title: l10n.account,
                      theme: theme,
                      children: [
                        _buildSubListItem(
                          l10n.editProfile,
                          context,
                          l10n: l10n,
                          theme: theme,
                          onTap: () {
                            final currentName = userProfileAsync.value?.displayName ?? '';
                            _showEditProfileDialog(context, ref, currentName);
                          },
                        ),
                        _buildSubListItem(
                          l10n.changePassword,
                          context,
                          l10n: l10n,
                          theme: theme,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const ChangePasswordPage()));
                          },
                        ),
                        // --- REFACTOR: Moved delete account option here ---
                        _buildSubListItem(
                          l10n.deleteAccount,
                          context,
                          l10n: l10n,
                          theme: theme,
                          isDestructive: true,
                          onTap: () => _showConfirmDeleteDialog(context, ref),
                        ),
                      ],
                    ),
                    if (isPremium)
                      _buildAccountCard(
                        icon: Icons.workspace_premium_outlined,
                        title: l10n.premium,
                        theme: theme,
                        children: [
                          _buildSubListItem(
                            l10n.manageSubscription,
                            context,
                            l10n: l10n,
                            theme: theme,
                            onTap: () => _manageSubscription(context, ref),
                          ),
                        ],
                      ),
                    // --- REFACTOR: Removed the separate Danger Zone card ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      child: Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        color: theme.background,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Icon(Icons.logout, color: theme.accent, size: 28),
                          title: Text(l10n.logout, style: TextStyle(color: theme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
                          onTap: () => _showStyledLogoutDialog(context, ref),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper UI methods

  Widget _buildUserInfoHeader({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required AppThemeData theme,
    required User? user,
    String? displayName,
    required bool isPremium,
  }) {
    // --- FIX: Replaced deprecated withOpacity with withAlpha ---
    final statusColor = isPremium ? theme.accent : theme.inactive.withAlpha((255 * 0.7).round());
    final statusText = isPremium ? l10n.accountStatusPremium : l10n.accountStatusFree;

    return GestureDetector(
      onLongPress: () async {
        try {
          await ref.read(userProfileNotifierProvider.notifier).updateUserPremiumStatus(!isPremium);
          // --- FIX: Handled unused_result warning ---
          final _ = ref.refresh(userProfileProvider);
          // --- FIX: Add context mounted check after async gap ---
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isPremium ? 'Developer Mode: Set to FREE' : 'Developer Mode: Set to PREMIUM'),
            duration: const Duration(seconds: 1),
          ));
        } catch (e) {
          // --- FIX: Add context mounted check after async gap ---
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e'), backgroundColor: theme.accent));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: 35, backgroundColor: theme.background, child: Icon(Icons.person_outline, size: 40, color: theme.secondary)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName ?? l10n.user, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.inactive), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  // --- FIX: Replaced deprecated withOpacity with withAlpha ---
                  Text(user?.email ?? l10n.noEmailAvailable, style: TextStyle(fontSize: 14, color: theme.inactive.withAlpha((255 * 0.7).round())), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    // --- FIX: Replaced deprecated withOpacity with withAlpha ---
                    decoration: BoxDecoration(color: statusColor.withAlpha((255 * 0.2).round()), borderRadius: BorderRadius.circular(6)),
                    child: Text(statusText.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  ),
                  if (!isPremium) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => showUpgradeDialog(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          // --- FIX: Replaced deprecated withOpacity with withAlpha ---
                          color: theme.accent.withAlpha((255 * 0.15).round()),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.accent, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_purple500_outlined, color: theme.accent, size: 18),
                            const SizedBox(width: 6),
                            Text(l10n.upgradeButton, style: TextStyle(color: theme.accent, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard({required IconData icon, required String title, required List<Widget> children, required AppThemeData theme}) {
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
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: theme.secondary, size: 28),
        title: Text(title, style: TextStyle(color: theme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
        children: children,
      ),
    );
  }

  Widget _buildSubListItem(
      String title,
      BuildContext context, {
        required AppLocalizations l10n,
        required AppThemeData theme,
        required VoidCallback onTap,
        bool isDestructive = false,
      }) {
    final color = isDestructive ? theme.accent : theme.inactive;
    return ListTile(
      title: Text(title, style: TextStyle(color: color)),
      contentPadding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
      onTap: onTap,
    );
  }
}