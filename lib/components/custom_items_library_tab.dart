// lib/components/custom_items_library_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class CustomItemsLibraryTab extends ConsumerWidget {
  // ADDED: Callback to tell the parent page to open the edit sheet
  final Function(Product) onEditItem;

  const CustomItemsLibraryTab({
    super.key,
    required this.onEditItem, // Make it required
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final customItemsAsync = ref.watch(customItemsProvider);
    final l10n = AppLocalizations.of(context)!;

    return customItemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(l10n.error(err.toString()))),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                l10n.customItemsEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.inactive.withOpacity(0.7), fontSize: 16),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              color: theme.background,
              child: ListTile(
                title: Text(item.name, style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  item.category == 'custom' ? item.subcategory : item.category,
                  style: TextStyle(color: theme.inactive.withOpacity(0.7)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: theme.secondary),
                      tooltip: l10n.editCustomItem,
                      onPressed: () {
                        // CHANGED: Call the callback passed from the parent page
                        onEditItem(item);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.secondary),
                      tooltip: l10n.delete,
                      onPressed: () => _showDeleteConfirmation(context, ref, item),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Product item) {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(l10n.deleteItemConfirmationTitle(item.name), style: TextStyle(color: theme.secondary)),
          content: Text(
            l10n.deleteItemConfirmationBody,
            style: TextStyle(color: theme.inactive),
          ),
          actions: [
            TextButton(
              child: Text(l10n.cancel, style: TextStyle(color: theme.inactive.withOpacity(0.7))),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: theme.secondary),
              child: Text(l10n.delete),
              onPressed: () {
                ref.read(firestoreServiceProvider).deleteCustomItemFromStorage(item.id);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}