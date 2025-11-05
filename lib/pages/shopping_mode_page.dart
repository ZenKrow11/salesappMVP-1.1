// lib/pages/shopping_mode_page.dart

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/settings_provider.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:auto_size_text/auto_size_text.dart';



class ShoppingModeScreen extends ConsumerStatefulWidget {
  const ShoppingModeScreen({super.key});

  @override
  ConsumerState<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends ConsumerState<ShoppingModeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final asyncShoppingList = ref.watch(filteredAndSortedShoppingListProvider);
    final shoppingModeState = ref.watch(shoppingModeProvider);
    final localizations = AppLocalizations.of(context)!;
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final shoppingModeNotifier = ref.read(shoppingModeProvider.notifier);

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: theme.secondary, size: 32),
          onPressed: () {
            ref.read(shoppingModeProvider.notifier).resetState();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          localizations.shoppingMode,
          style: TextStyle(color: theme.secondary),
        ),
        actions: [
          IconButton(
            icon: Icon(
              settingsState.hideCheckedItemsInShoppingMode
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: theme.secondary,
            ),
            tooltip: settingsState.hideCheckedItemsInShoppingMode
                ? "Show checked items"
                : "Hide checked items",
            onPressed: () => settingsNotifier.toggleHideCheckedItems(),
          ),
        ],
      ),
      bottomNavigationBar: asyncShoppingList.when(
        data: (products) {
          final activeProducts =
          products.where((product) => product.isOnSale).toList();
          return activeProducts.isNotEmpty
              ? _buildSummaryBar(context, ref, activeProducts, shoppingModeState) // This method is now restored
              : const SizedBox.shrink();
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      body: asyncShoppingList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(localizations.error(error.toString()))),
        data: (products) {
          final activeProducts =
          products.where((product) => product.isOnSale).toList();

          final visibleProducts = settingsState.hideCheckedItemsInShoppingMode
              ? activeProducts
              .where((p) =>
          !shoppingModeState.checkedProductIds.contains(p.id))
              .toList()
              : activeProducts;

          if (visibleProducts.isEmpty) {
            return Center(
              child: Text(
                localizations.shoppingListEmpty,
                style: TextStyle(color: theme.inactive),
              ),
            );
          }

          final sortOption = ref.watch(homePageFilterStateProvider).sortOption;

          final Map<String, List<Product>> groupedProducts;
          final List<String> orderedGroupNames;

          if (sortOption == SortOption.storeAlphabetical) {
            groupedProducts =
                groupBy(visibleProducts, (Product p) => p.store);
            orderedGroupNames = groupedProducts.keys.toList()..sort();
          } else {
            groupedProducts = groupBy(
              visibleProducts,
                  (Product p) =>
              p.category.isEmpty ? 'categoryUncategorized' : p.category,
            );
            orderedGroupNames = categoryDisplayOrder
                .where((name) => groupedProducts.containsKey(name))
                .toList();
            final remainingGroups = groupedProducts.keys
                .where((key) => !orderedGroupNames.contains(key))
                .toList();
            orderedGroupNames.addAll(remainingGroups);
          }

          return ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: MaterialStateProperty.all(
                  theme.secondary.withOpacity(0.7)),
              radius: const Radius.circular(4),
              thickness: MaterialStateProperty.all(6.0),
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: false,
              interactive: true,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  for (final groupName in orderedGroupNames) ...[
                    SliverPersistentHeader(
                      pinned: false,
                      delegate: _SliverHeaderDelegate(
                        child: Container(
                          color: theme.pageBackground,
                          child: _buildCompactGroupSeparator(
                              groupName, context, theme, sortOption),
                        ),
                        height: 58,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final product = groupedProducts[groupName]![index];
                          final isChecked = shoppingModeState
                              .checkedProductIds
                              .contains(product.id);
                          final quantity = shoppingModeState
                              .productQuantities[product.id] ??
                              1;

                          return ShoppingModeListItemTile(
                            product: product,
                            isChecked: isChecked,
                            quantity: quantity,
                            onCheckTap: () =>
                                shoppingModeNotifier.toggleChecked(product.id),
                            onInfoTap: () =>
                                _showItemDetailsBottomSheet(context, ref, product), // This now calls the modernized version
                          );
                        },
                        childCount: groupedProducts[groupName]!.length,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactGroupSeparator(
      String groupName, BuildContext context, AppThemeData theme, SortOption sortOption) {
    final localizations = AppLocalizations.of(context)!;
    final String displayName;
    if (sortOption == SortOption.storeAlphabetical) {
      displayName = groupName;
    } else {
      final style =
      CategoryService.getLocalizedStyleForGroupingName(groupName, localizations);
      displayName = style.displayName;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName.toUpperCase(),
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

  // --- THIS IS THE NEW MODERNIZED BOTTOM SHEET METHOD ---
  void _showItemDetailsBottomSheet(
      BuildContext context, WidgetRef ref, Product product) {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take up more height
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(shoppingModeProvider);
            final notifier = ref.read(shoppingModeProvider.notifier);
            final currentQuantity = state.productQuantities[product.id] ?? 1;
            final totalPrice = product.currentPrice * currentQuantity;

            // Use a container that takes up 70% of the screen height.
            // This gives the Expanded widget inside a defined space to work with.
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              // The main layout is a Column.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- 1. PRODUCT NAME ---
                  AutoSizeText(
                    product.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white),
                    maxLines: 2,
                    minFontSize: 18,
                  ),
                  const SizedBox(height: 16),

                  // --- 2. IMAGE (RESPONSIVE) ---
                  // ** THIS IS THE CRITICAL FIX **
                  // Expanded allows the image to shrink vertically on smaller screens,
                  // ensuring the buttons below are never pushed off-screen.
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // White background
                          Container(color: Colors.white),
                          // Image
                          ImageWithAspectRatio(
                            imageUrl: product.imageUrl,
                            maxHeight: 400, // It can be this tall...
                            maxWidth: double.infinity,
                            fit: BoxFit.contain,
                          ),
                          // Store Logo Overlay
                          Positioned(
                            top: 8,
                            left: 8,
                            child:
                            StoreLogo(storeName: product.store, height: 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 3. PRICE x QUANTITY = TOTAL ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${product.currentPrice.toStringAsFixed(2)} Fr.', style: TextStyle(color: theme.inactive, fontSize: 16)),
                        Text('x $currentQuantity', style: TextStyle(color: theme.inactive, fontSize: 16)),
                        Text('= ${totalPrice.toStringAsFixed(2)} Fr.', style: TextStyle(color: theme.secondary, fontWeight: FontWeight.bold, fontSize: 20)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- 4. BUTTONS ---
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: currentQuantity > 1
                              ? () => notifier.decrementQuantity(product.id)
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: theme.accent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Icon(Icons.remove, color: theme.accent, size: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => notifier.incrementQuantity(product.id),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: theme.secondary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Icon(Icons.add, color: theme.secondary, size: 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- THIS METHOD IS NOW RESTORED ---
  Widget _buildSummaryBar(BuildContext context, WidgetRef ref,
      List<Product> products, ShoppingModeState shoppingModeState) {
    final theme = ref.watch(themeProvider);
    final localizations = AppLocalizations.of(context)!;

    final double totalCost = products.fold(0.0, (sum, product) {
      final quantity = shoppingModeState.productQuantities[product.id] ?? 1;
      return sum + (product.currentPrice * quantity);
    });

    // --- FIX: Sum the quantities instead of just counting the products ---
    final int totalItems = products.fold(0, (sum, product) {
      final quantity = shoppingModeState.productQuantities[product.id] ?? 1;
      return sum + quantity;
    });

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: theme.primary,
          border:
          Border(top: BorderSide(color: theme.background, width: 1.0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations.itemsLabel.toUpperCase(),
                  style: TextStyle(
                      color: theme.inactive.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalItems',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations.total.toUpperCase(),
                  style: TextStyle(
                      color: theme.inactive.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalCost.toStringAsFixed(2)} ${localizations.currencyFrancs}',
                  style: TextStyle(
                      color: theme.secondary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showFinishShoppingDialog(context, ref, products),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(localizations.finish),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
                foregroundColor: theme.primary,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- THIS METHOD IS NOW RESTORED ---
  Future<void> _showFinishShoppingDialog(
      BuildContext context, WidgetRef ref, List<Product> allProducts) async {
    final theme = ref.read(themeProvider);
    final localizations = AppLocalizations.of(context)!;
    final shoppingModeNotifier = ref.read(shoppingModeProvider.notifier);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.background,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(localizations.finishShoppingTitle,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(localizations.finishShoppingBody,
              style:
              TextStyle(color: theme.inactive.withOpacity(0.8))),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  child: Text(localizations.cancel,
                      style: TextStyle(
                          color: theme.inactive.withOpacity(0.6))),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                TextButton(
                  child: Text(localizations.keepAllItems,
                      style: TextStyle(
                          color: theme.secondary,
                          fontWeight: FontWeight.bold)),
                  onPressed: () {
                    shoppingModeNotifier.resetState();
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(localizations.removeCheckedItems,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    final checkedIds =
                        ref.read(shoppingModeProvider).checkedProductIds;
                    final listNotifier =
                    ref.read(shoppingListsProvider.notifier);

                    for (final productId in checkedIds) {
                      final productToRemove = allProducts
                          .firstWhere((p) => p.id == productId);
                      listNotifier.removeItemFromList(productToRemove);
                    }
                    shoppingModeNotifier.resetState();
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

// This class does not need changes, but is required for the screen to build.
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
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) =>
      height != oldDelegate.height || child != oldDelegate.child;
}