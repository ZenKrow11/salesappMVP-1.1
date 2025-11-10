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
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/settings_provider.dart';
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
          style: TextStyle(
            color: theme.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
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
              ? _buildSummaryBar(context, ref, activeProducts, shoppingModeState)
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
            groupedProducts = groupBy(visibleProducts, (Product p) => p.store);
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
              thumbColor:
              MaterialStateProperty.all(theme.secondary.withOpacity(0.7)),
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
                          final quantity =
                              shoppingModeState.productQuantities[product.id] ??
                                  1;

                          return ShoppingModeListItemTile(
                            product: product,
                            isChecked: isChecked,
                            quantity: quantity,
                            onCheckTap: () =>
                                shoppingModeNotifier.toggleChecked(product.id),
                            onInfoTap: () => _showItemDetailsBottomSheet(
                                context, ref, product),
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

  // --- Bottom Sheet for item details ---
  void _showItemDetailsBottomSheet(
      BuildContext context, WidgetRef ref, Product product) {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AutoSizeText(
                    product.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    minFontSize: 18,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(color: Colors.white),
                          ImageWithAspectRatio(
                            imageUrl: product.imageUrl,
                            maxHeight: 400,
                            maxWidth: double.infinity,
                            fit: BoxFit.contain,
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: StoreLogo(storeName: product.store, height: 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${product.currentPrice.toStringAsFixed(2)} Fr.',
                            style: TextStyle(color: theme.inactive, fontSize: 16)),
                        Text('x $currentQuantity',
                            style: TextStyle(color: theme.inactive, fontSize: 16)),
                        Text('= ${totalPrice.toStringAsFixed(2)} Fr.',
                            style: TextStyle(
                                color: theme.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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

  // --- Summary Bar (unchanged) ---
  Widget _buildSummaryBar(BuildContext context, WidgetRef ref,
      List<Product> products, ShoppingModeState shoppingModeState) {
    final theme = ref.watch(themeProvider);
    final localizations = AppLocalizations.of(context)!;

    final double totalCost = products.fold(0.0, (sum, product) {
      final quantity = shoppingModeState.productQuantities[product.id] ?? 1;
      return sum + (product.currentPrice * quantity);
    });

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
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFinishShoppingDialog(
      BuildContext context, WidgetRef ref, List<Product> allProducts) async {
    final theme = ref.read(themeProvider);
    final localizations = AppLocalizations.of(context)!;

    final shoppingModeState = ref.read(shoppingModeProvider);
    final finalQuantities = shoppingModeState.productQuantities;

    // Quick summary
    final totalItems = finalQuantities.values.fold<int>(0, (a, b) => a + b);
    final totalCost = allProducts.fold<double>(
      0,
          (sum, p) => sum + (p.currentPrice * (finalQuantities[p.id] ?? 1)),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Handle bar ---
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.inactive.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),

              // --- Title ---
              Icon(Icons.shopping_bag_outlined,
                  size: 44, color: theme.secondary),
              const SizedBox(height: 8),
              Text(
                localizations.finishShoppingTitle,
                style: TextStyle(
                  color: theme.inactive,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.finishShoppingBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.inactive.withOpacity(0.7),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),

              // --- Quick summary row ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.background.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.shopping_cart_outlined,
                          color: theme.secondary, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        "$totalItems ${localizations.itemsLabel}",
                        style: TextStyle(color: theme.inactive, fontSize: 15),
                      ),
                    ]),
                    Text(
                      "${totalCost.toStringAsFixed(2)} ${localizations.currencyFrancs}",
                      style: TextStyle(
                        color: theme.secondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --- Buttons ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ Remove checked items
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 22),
                    label: Text(
                      localizations.removeCheckedItems,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.secondary,
                      foregroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      // Show loading overlay
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => Center(
                          child: CircularProgressIndicator(color: theme.secondary),
                        ),
                      );

                      final listNotifier = ref.read(shoppingListsProvider.notifier);
                      final shoppingModeNotifier = ref.read(shoppingModeProvider.notifier);
                      final finalQuantities = ref.read(shoppingModeProvider).productQuantities;
                      final checkedIds = ref.read(shoppingModeProvider).checkedProductIds;

                      try {
                        // 1️⃣ Save latest quantities
                        await listNotifier.updateItemQuantities(finalQuantities);

                        // 2️⃣ Remove checked items sequentially
                        for (final productId in checkedIds) {
                          final productToRemove =
                          allProducts.firstWhere((p) => p.id == productId);
                          // Re-read notifier fresh each iteration to avoid stale ref
                          await ref.read(shoppingListsProvider.notifier)
                              .removeItemFromList(productToRemove);
                        }

                        // 3️⃣ Reset state only after removals are done
                        shoppingModeNotifier.resetState();

                        // 4️⃣ Pop only when context is still mounted
                        if (context.mounted) {
                          Navigator.of(context).pop(); // close loading
                          Navigator.of(context).pop(); // close sheet
                          Navigator.of(context).pop(); // leave shopping mode
                        }
                      } catch (e, st) {
                        debugPrint('Error while removing items: $e\n$st');
                        // Optionally, pop the loading dialog and show an error message
                        if (context.mounted) {
                          Navigator.of(context).pop(); // close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to remove items.'))
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // 🧺 Keep all items
                  OutlinedButton.icon(
                    icon: const Icon(Icons.shopping_basket_outlined, size: 22),
                    label: Text(
                      localizations.keepAllItems,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.secondary, width: 1.5),
                      foregroundColor: theme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => Center(
                          child: CircularProgressIndicator(
                            color: theme.secondary,
                          ),
                        ),
                      );

                      final listNotifier = ref.read(shoppingListsProvider.notifier);
                      final shoppingModeNotifier = ref.read(shoppingModeProvider.notifier);

                      await listNotifier.updateItemQuantities(finalQuantities);
                      shoppingModeNotifier.resetState();

                      if (context.mounted) {
                        Navigator.of(context).pop(); // close loading
                        Navigator.of(context).pop(); // close sheet
                        Navigator.of(context).pop(); // leave shopping mode
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // ❌ Cancel
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      localizations.cancel,
                      style: TextStyle(
                        color: theme.inactive.withOpacity(0.6),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;
  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) =>
      height != oldDelegate.height || child != oldDelegate.child;
}