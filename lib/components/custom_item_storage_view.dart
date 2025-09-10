// lib/components/custom_item_storage_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/create_custom_item_page.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class CustomItemStorageView extends ConsumerWidget {
  const CustomItemStorageView({super.key});

  void _showOptionsDialog(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            child: const Text('Edit'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CreateCustomItemPage(productToEdit: product),
              ));
            },
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation(context, ref, product);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to permanently delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
            onPressed: () async {
              try {
                await ref.read(firestoreServiceProvider).deleteCustomItemFromStorage(product.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${product.name}" deleted.'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting item: $e'), backgroundColor: Theme.of(context).colorScheme.error),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final customItemsAsync = ref.watch(customItemsProvider);

    return customItemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading items: $err')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'You haven\'t created any custom items yet.\nUse the menu to create your first one!',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.inactive.withOpacity(0.7), fontSize: 16),
              ),
            ),
          );
        }
        // --- THE FIX IS HERE ---
        // The Card and InkWell logic must be INSIDE the ListView.builder's itemBuilder.
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            // 'product' is defined here for each item in the list
            final product = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: theme.background,
              child: InkWell(
                onLongPress: () => _showOptionsDialog(context, ref, product),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 0, 8), // Adjusted padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: TextStyle(color: theme.inactive, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              product.category == 'custom' ? product.subcategory : product.category,
                              style: TextStyle(color: theme.inactive.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: theme.secondary, size: 32),
                        tooltip: 'Add to current shopping list',
                        onPressed: () {
                          final activeListId = ref.read(activeShoppingListProvider);
                          ref.read(shoppingListsProvider.notifier).addToSpecificList(product, activeListId);

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Added "${product.name}" to your list.'),
                            duration: const Duration(seconds: 2),
                          ));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}