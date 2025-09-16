// lib/components/custom_items_library_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class CustomItemsLibraryTab extends ConsumerWidget {
  const CustomItemsLibraryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final customItemsAsync = ref.watch(customItemsProvider);

    return customItemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'You haven\'t created any custom items yet.',
              textAlign: TextAlign.center,
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
                      onPressed: () {
                        // TODO: Implement navigation to an edit screen if needed
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit functionality coming soon!')),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.accent),
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
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Delete "${item.name}"?', style: TextStyle(color: theme.secondary)),
          content: Text(
            'This will permanently remove the item from your library.',
            style: TextStyle(color: theme.inactive),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: theme.inactive.withOpacity(0.7))),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: theme.accent),
              child: const Text('Delete'),
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