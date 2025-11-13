// lib/components/upgrade_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

void showUpgradeDialog(BuildContext context, WidgetRef ref) {
  final theme = ref.read(themeProvider);
  final l10n = AppLocalizations.of(context)!;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.upgradeToPremiumTitle,
            style: TextStyle(color: theme.secondary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- NO CHANGE: The feature list remains the same ---
            Text(l10n.upgradeToPremiumFeature1, style: TextStyle(color: theme.inactive)),
            const SizedBox(height: 8),
            Text(l10n.upgradeToPremiumFeature2, style: TextStyle(color: theme.inactive)),
            const SizedBox(height: 8),
            Text(l10n.upgradeToPremiumFeature3, style: TextStyle(color: theme.inactive)),

            // --- CHANGE 1: ADD THE "COMING SOON" MESSAGE ---
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: theme.secondary.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.secondary.withAlpha(128))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.new_releases_outlined, color: theme.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    // You can create a new key in your l10n file for this
                    "Premium Coming Soon!",
                    style: TextStyle(
                      color: theme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(l10n.cancel, style: TextStyle(color: theme.inactive)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // --- CHANGE 2: DISABLE THE UPGRADE BUTTON ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              // Use a "disabled" look for the button
              backgroundColor: theme.inactive.withAlpha(77),
              foregroundColor: theme.inactive.withAlpha(179),
            ),
            // Setting onPressed to null automatically disables the button
            onPressed: null,
            child: const Text("Upgrade"), // The text can remain "Upgrade" or change
          ),
        ],
      );
    },
  );
}