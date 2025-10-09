// lib/components/upgrade_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/services/purchase_service.dart'; // Import the new service
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
            Text(l10n.upgradeToPremiumFeature1, style: TextStyle(color: theme.inactive)),
            SizedBox(height: 8),
            Text(l10n.upgradeToPremiumFeature2, style: TextStyle(color: theme.inactive)),
            SizedBox(height: 8),
            Text(l10n.upgradeToPremiumFeature3, style: TextStyle(color: theme.inactive)),
          ],
        ),
        actions: [
          TextButton(
            child: Text(l10n.cancel, style: TextStyle(color: theme.inactive)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.upgradeButton),
            onPressed: () {
              // THIS IS THE KEY! Call your PurchaseService to start the payment flow.
              ref.read(purchaseServiceProvider).buyPremium();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}