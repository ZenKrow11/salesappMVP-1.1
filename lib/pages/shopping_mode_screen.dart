// lib/pages/shopping_mode_screen.dart

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'package:sales_app_mvp/models/category_definitions.dart';

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
        automaticallyImplyLeading: false,
        title: Text(
          l10n.shoppingMode,
          style: TextStyle(color: theme.secondary),
        ),
        actions: [
          // This is your trailing, accent-colored close button
          IconButton(
            icon: Icon(Icons.close, color: theme.accent), // Corrected theme color
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      bottomNavigationBar: asyncShoppingList.when(
        data: (products) => products.isNotEmpty
            ? _buildSummaryBar(context, ref, products, shoppingModeState)
            : const SizedBox.shrink(),
        loading: () => const SizedBox.shrink(),
        error: (err, stack) => const SizedBox.shrink(),
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

          final groupedProducts = groupBy(products, (Product p) => (p.category.isEmpty) ? 'categoryUncategorized' : p.category);

          final orderedGroupNames = categoryDisplayOrder.where((name) => groupedProducts.containsKey(name)).toList();

          final remainingGroups = groupedProducts.keys.where((key) => !orderedGroupNames.contains(key)).toList();
          orderedGroupNames.addAll(remainingGroups);

          return CustomScrollView(
            slivers: [
              for (final groupName in orderedGroupNames) ...[
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverHeaderDelegate(
                    child: Container(
                      color: theme.pageBackground,
                      child: _buildCompactGroupSeparator(groupName, context, theme),
                    ),
                    height: 58,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final product = groupedProducts[groupName]![index];
                      final isChecked = shoppingModeState.checkedProductIds.contains(product.id);
                      final quantity = shoppingModeState.productQuantities[product.id] ?? 1;

                      return ShoppingModeListItemTile(
                        product: product,
                        isChecked: isChecked,
                        quantity: quantity,
                        onCheckTap: () => shoppingModeNotifier.toggleChecked(product.id),
                        onInfoTap: () => _showItemDetailsBottomSheet(context, ref, product),
                      );
                    },
                    childCount: groupedProducts[groupName]!.length,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactGroupSeparator(String groupFirestoreName, BuildContext context, AppThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final style = CategoryService.getLocalizedStyleForGroupingName(groupFirestoreName, l10n);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            style.displayName.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              color: theme.inactive.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: theme.background, height: 1),
        ],
      ),
    );
  }

  void _showItemDetailsBottomSheet(BuildContext context, WidgetRef ref, Product product) {
    final theme = ref.read(themeProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(shoppingModeProvider);
            final notifier = ref.read(shoppingModeProvider.notifier);
            final currentQuantity = state.productQuantities[product.id] ?? 1;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
                      ),
                      if (product.store.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            product.store,
                            style: TextStyle(fontSize: 16, color: theme.inactive.withOpacity(0.7)),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: ImageWithAspectRatio(
                            imageUrl: product.imageUrl,
                            maxWidth: 200, maxHeight: 200,
                          ),
                        ),
                      ),
                      Text(
                        '${product.currentPrice.toStringAsFixed(2)} Fr.',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: theme.secondary),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      QuantityStepper(
                        quantity: currentQuantity,
                        onIncrement: () => notifier.incrementQuantity(product.id),
                        onDecrement: () => notifier.decrementQuantity(product.id),
                      ),
                      const SizedBox(height: 16),
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

  Widget _buildSummaryBar(BuildContext context, WidgetRef ref, List<Product> products, ShoppingModeState shoppingModeState) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    final double totalCost = products.fold(0.0, (sum, product) {
      final quantity = shoppingModeState.productQuantities[product.id] ?? 1;
      return sum + (product.currentPrice * quantity);
    });

    final int totalItems = products.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.primary,
        border: Border(top: BorderSide(color: theme.background, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Item Count Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.itemsLabel.toUpperCase(),
                style: TextStyle(color: theme.inactive.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalItems',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // Total Cost Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.total.toUpperCase(),
                style: TextStyle(color: theme.inactive.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${totalCost.toStringAsFixed(2)} ${l10n.currencyFrancs}',
                style: TextStyle(color: theme.secondary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // Finish Button
          ElevatedButton.icon(
            onPressed: () => _showFinishShoppingDialog(context, ref, products),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(l10n.finish),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.secondary,
              foregroundColor: theme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _showFinishShoppingDialog(BuildContext context, WidgetRef ref, List<Product> allProducts) async {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.finishShoppingTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(l10n.finishShoppingBody, style: TextStyle(color: theme.inactive.withOpacity(0.8))),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  child: Text(l10n.cancel, style: TextStyle(color: theme.inactive.withOpacity(0.6))),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                TextButton(
                  child: Text(l10n.keepAllItems, style: TextStyle(color: theme.secondary, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(l10n.removeCheckedItems, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            )
          ],
        );
      },
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}