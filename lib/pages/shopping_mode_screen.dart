// lib/pages/shopping_mode_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:sales_app_mvp/components/shopping_mode_list_item_tile.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class ShoppingModeScreen extends ConsumerStatefulWidget {
  const ShoppingModeScreen({super.key});

  @override
  ConsumerState<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends ConsumerState<ShoppingModeScreen> {
  final Set<String> _checkedProductIds = {};

  void _toggleChecked(String productId) {
    setState(() {
      if (_checkedProductIds.contains(productId)) {
        _checkedProductIds.remove(productId);
      } else {
        _checkedProductIds.add(productId);
      }
    });
  }

  // NEW: This method builds and shows the confirmation dialog.
  Future<void> _showFinishShoppingDialog(List<Product> allProducts) async {
    final theme = ref.read(themeProvider);
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Finish Shopping?'),
          content: const Text('Would you like to remove the items you checked off from your list?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: theme.inactive)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              child: const Text('Keep All Items'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                Navigator.of(context).pop(); // Go back to Management screen
              },
            ),
            // This is the primary action button.
            ElevatedButton(
              child: const Text('Remove Checked Items'),
              onPressed: () {
                final notifier = ref.read(shoppingListsProvider.notifier);
                // Loop through all checked IDs and call the remove function
                for (final productId in _checkedProductIds) {
                  // We need to find the full product object to pass to the notifier
                  final productToRemove = allProducts.firstWhere((p) => p.id == productId);
                  notifier.removeItemFromList(productToRemove);
                }
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                Navigator.of(context).pop(); // Go back to Management screen
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        elevation: 0,
        title: const Text('Shopping Mode'),
        actions: [
          // A button to clear all checks without finishing
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Uncheck All Items',
            onPressed: () {
              setState(() {
                _checkedProductIds.clear();
              });
            },
          ),
        ],
      ),
      // NEW: Added a FloatingActionButton for the main "Finish" action.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // It only makes sense to show the dialog if there are products in the list.
          if (asyncShoppingList.hasValue) {
            _showFinishShoppingDialog(asyncShoppingList.value!);
          }
        },
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Finish'),
      ),
      body: asyncShoppingList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Text('Your shopping list is empty.', style: TextStyle(color: theme.inactive)),
            );
          }
          return GroupedListView<Product, String>(
            elements: products,
            groupBy: (product) => CategoryService.getGroupingDisplayNameForProduct(product),
            useStickyGroupSeparators: true,
            stickyHeaderBackgroundColor: theme.pageBackground,
            groupSeparatorBuilder: (String groupName) {
              final style = CategoryService.getStyleForGroupingName(groupName);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: style.color,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        style.iconAssetPath,
                        height: 20,
                        width: 20,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        groupName,
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
            itemBuilder: (context, product) {
              final isChecked = _checkedProductIds.contains(product.id);
              return ShoppingModeListItemTile(
                product: product,
                isChecked: isChecked,
                onTap: () => _toggleChecked(product.id),
              );
            },
            order: GroupedListOrder.ASC,
          );
        },
      ),
    );
  }
}