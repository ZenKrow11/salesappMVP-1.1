// lib/components/manage_list_items_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class ManageListItemsBottomSheet extends ConsumerWidget {
  const ManageListItemsBottomSheet({super.key});

  // --- THIS DIALOG IS NOW UPDATED TO MATCH THE REST OF THE APP ---
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: TextStyle(
                color: theme.secondary, fontWeight: FontWeight.bold)),
        content: Text(content, style: TextStyle(color: theme.inactive)),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.inactive,
              side: BorderSide(color: theme.inactive.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: theme.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Text(confirmText),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    ) ??
        false;
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
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.secondary),
              ),
              const SizedBox(height: 24),
              // --- THIS IS THE FIX: A ROW FOR SIDE-BY-SIDE BUTTONS ---
              Row(
                children: [
                  // Button 1: Purge Expired
                  Expanded(
                    child: FilledButton.icon(
                      icon: Icon(Icons.lock_open_outlined, color: theme.primary),
                      label: Text(
                        l10n.purgeButtonLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.secondary,
                        foregroundColor: theme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final confirmed = await _showConfirmationDialog(
                          context,
                          theme,
                          l10n,
                          title: l10n.purgeExpiredConfirmationTitle,
                          content: l10n.purgeExpiredConfirmationBody,
                          confirmText: l10n.purgeButton,
                        );
                        if (!context.mounted) return;
                        if (confirmed) {
                          await ref
                              .read(shoppingListsProvider.notifier)
                              .purgeExpiredItems();
                          ref.refresh(shoppingListWithDetailsProvider);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Button 2: Clear All
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: Text(
                        l10n.clearAllButtonLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final confirmed = await _showConfirmationDialog(
                          context,
                          theme,
                          l10n,
                          title: l10n.clearAllConfirmationTitle,
                          content: l10n.clearAllConfirmationBody,
                          confirmText: l10n.clearAllButton,
                        );
                        if (!context.mounted) return;
                        if (confirmed) {
                          await ref
                              .read(shoppingListsProvider.notifier)
                              .clearActiveList();
                          ref.refresh(shoppingListWithDetailsProvider);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}