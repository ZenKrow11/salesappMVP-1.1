// lib/components/manage_list_items_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class ManageListItemsBottomSheet extends ConsumerWidget {
  const ManageListItemsBottomSheet({super.key});

  Future<bool> _showConfirmationDialog(
      BuildContext context,
      AppThemeData theme,
      AppLocalizations l10n, {
        required String title,
        required String content,
        required String confirmText,
      }) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.background,
        title: Text(title, style: TextStyle(color: theme.secondary)),
        content: Text(content, style: TextStyle(color: theme.inactive)),
        actions: [
          TextButton(
            child: Text(l10n.cancel, style: TextStyle(color: theme.inactive)),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.accent),
            child: Text(confirmText),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.manageItemsTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.secondary),
            ),
            const SizedBox(height: 24),

            // Button 1: Purge Expired
            OutlinedButton.icon(
              icon: const Icon(Icons.cleaning_services_outlined),
              label: Text(l10n.purgeButtonLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.inactive,
                side: BorderSide(color: theme.inactive.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                // --- THIS IS THE FIX ---
                // 1. Show dialog and wait for confirmation.
                final confirmed = await _showConfirmationDialog(
                  context, theme, l10n,
                  title: l10n.purgeExpiredConfirmationTitle,
                  content: l10n.purgeExpiredConfirmationBody,
                  confirmText: l10n.purgeButton,
                );

                // This is a safety check. If the widget was somehow removed
                // during the await, we don't proceed.
                if (!context.mounted) return;

                // 2. If confirmed, perform all actions.
                if (confirmed) {
                  await ref.read(shoppingListsProvider.notifier).purgeExpiredItems();
                  ref.refresh(shoppingListWithDetailsProvider);
                  // 3. Only pop the sheet AFTER everything is done.
                  Navigator.of(context).pop();
                }
              },
            ),

            const SizedBox(height: 16),

            // Button 2: Clear All
            FilledButton.icon(
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(l10n.clearAllButtonLabel),
              style: FilledButton.styleFrom(
                backgroundColor: theme.accent.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                // --- APPLY THE SAME FIX HERE ---
                // 1. Show dialog and wait.
                final confirmed = await _showConfirmationDialog(
                  context, theme, l10n,
                  title: l10n.clearAllConfirmationTitle,
                  content: l10n.clearAllConfirmationBody,
                  confirmText: l10n.clearAllButton,
                );

                if (!context.mounted) return;

                // 2. If confirmed, do the work.
                if (confirmed) {
                  await ref.read(shoppingListsProvider.notifier).clearActiveList();
                  ref.refresh(shoppingListWithDetailsProvider);
                  // 3. Pop at the end.
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    ));
  }
}