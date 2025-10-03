// lib/pages/shopping_mode_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grouped_list/grouped_list.dart';

// Local project imports
import 'package:sales_app_mvp/components/shopping_mode_list_item_tile.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/shopping_mode_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/quantity_stepper.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';

class ShoppingModeScreen extends ConsumerWidget {
  const ShoppingModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
    final shoppingModeState = ref.watch(shoppingModeProvider);
    final shoppingModeNotifier = ref.read(shoppingModeProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        elevation: 0,
        title: Text(l10n.shoppingMode),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.uncheckAllItems,
            onPressed: shoppingModeNotifier.clearChecks,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (asyncShoppingList.hasValue) {
            _showFinishShoppingDialog(context, ref, asyncShoppingList.value!);
          }
        },
        icon: const Icon(Icons.check_circle_outline),
        label: Text(l10n.finish),
      ),
      body: asyncShoppingList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.error(err.toString()))),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Text(l10n.shoppingListEmpty, style: TextStyle(color: theme.inactive)),
            );
          }
          return GroupedListView<Product, String>(
            elements: products,
            // CORE FIX: Group by raw category ID
            groupBy: (product) => product.category,
            useStickyGroupSeparators: true,
            stickyHeaderBackgroundColor: theme.pageBackground,
            // CORE FIX: Pass context to translate the group ID
            groupSeparatorBuilder: (String groupFirestoreName) => _buildGroupSeparator(groupFirestoreName, context),
            itemBuilder: (context, product) {
              final isChecked = shoppingModeState.checkedProductIds.contains(product.id);
              final quantity = shoppingModeState.productQuantities[product.id] ?? 1;

              return ShoppingModeListItemTile(
                product: product,
                isChecked: isChecked,
                quantity: quantity,
                onCheckTap: () => shoppingModeNotifier.toggleChecked(product.id),
                onInfoTap: () => _showItemDetails(context, ref, product),
              );
            },
            order: GroupedListOrder.ASC,
          );
        },
      ),
    );
  }

  // FIX: Restored full _buildGroupSeparator method body
  Widget _buildGroupSeparator(String groupFirestoreName, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = CategoryService.getLocalizedStyleForGroupingName(groupFirestoreName, l10n);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: style.color, borderRadius: BorderRadius.circular(5.0)),
        child: Row(
          children: [
            SvgPicture.asset(style.iconAssetPath, height: 20, width: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
            const SizedBox(width: 8),
            Text(
              style.displayName, // Now correctly translated
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Restored full _showItemDetails method body
  void _showItemDetails(BuildContext context, WidgetRef ref, Product product) {
    final theme = ref.read(themeProvider);
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(shoppingModeProvider);
            final notifier = ref.read(shoppingModeProvider.notifier);
            final currentQuantity = state.productQuantities[product.id] ?? 1;

            return AlertDialog(
              contentPadding: const EdgeInsets.all(16.0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (product.store.isNotEmpty)
                      Text(
                        product.store,
                        style: TextStyle(fontSize: 16, color: theme.inactive),
                        textAlign: TextAlign.center,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        product.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: ImageWithAspectRatio(
                          imageUrl: product.imageUrl,
                          maxWidth: 250, maxHeight: 250,
                        ),
                      ),
                    ),
                    Text(
                      '${product.currentPrice.toStringAsFixed(2)} Fr.',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    QuantityStepper(
                      quantity: currentQuantity,
                      onIncrement: () => notifier.incrementQuantity(product.id),
                      onDecrement: () => notifier.decrementQuantity(product.id),
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

  // Restored full _showFinishShoppingDialog method body
  Future<void> _showFinishShoppingDialog(BuildContext context, WidgetRef ref, List<Product> allProducts) async {
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
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Keep All Items'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Remove Checked Items'),
              onPressed: () {
                final checkedIds = ref.read(shoppingModeProvider).checkedProductIds;
                final listNotifier = ref.read(shoppingListsProvider.notifier);

                for (final productId in checkedIds) {
                  final productToRemove = allProducts.firstWhere((p) => p.id == productId);
                  listNotifier.removeItemFromList(productToRemove);
                }
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}