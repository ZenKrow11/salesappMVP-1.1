// lib/components/custom_items_library_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/management_grid_tile.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/create_custom_item_page.dart';
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'You have no saved custom items.\nSwitch to the "Create New" tab to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.inactive.withOpacity(0.7), fontSize: 16),
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final product = items[index];
            return ManagementGridTile(
              product: product,
              allProductsInList: items,
              // SINGLE TAP now adds the item and closes the page
              onTap: () {
                _addItemAndDismiss(context, ref, product);
              },
              // LONG PRESS now opens the edit/delete options
              onLongPress: () {
                _showOptionsDialog(context, ref, product);
              },
            );
          },
        );
      },
    );
  }

  void _addItemAndDismiss(BuildContext context, WidgetRef ref, Product product) {
    final activeListId = ref.read(activeShoppingListProvider);
    ref.read(shoppingListsProvider.notifier).addToSpecificList(product, activeListId);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Added "${product.name}" to your list.'),
      duration: const Duration(seconds: 2),
    ));
  }

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
              // TODO: This should be updated to switch tabs and pass the product
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
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
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
        content: Text('Are you sure you want to permanently delete "${product.name}" from your library? This cannot be undone.'),
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
}