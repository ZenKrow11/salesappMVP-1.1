// lib/pages/shopping_list_page.dart

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/components/shopping_list_item_tile.dart';
import 'package:sales_app_mvp/components/shopping_summary_bar.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/providers/settings_provider.dart';


class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
    final theme = ref.watch(themeProvider);
    final isGridView = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return asyncShoppingList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(l10n.errorLoadingList(err.toString()))),
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                l10n.listIsEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: theme.inactive.withOpacity(0.7), fontSize: 16),
              ),
            ),
          );
        }

        // --- CORE FIX: Group by the raw, non-localized category ID (firestoreName) ---
        final groupedProducts = groupBy(products, (Product p) => p.category);

        final orderedGroupNames = categoryDisplayOrder.where((name) => groupedProducts.containsKey(name)).toList();

        final List<Product> flatSortedProducts = orderedGroupNames
            .expand((groupName) => groupedProducts[groupName]!)
            .toList();

        return Column(
          children: [
            Expanded(
              child: isGridView
                  ? _buildGroupedGridView(context, ref, flatSortedProducts, groupedProducts, orderedGroupNames, theme)
                  : _buildGroupedListView(context, ref, flatSortedProducts, groupedProducts, orderedGroupNames, theme),
            ),
            ShoppingSummaryBar(products: products),
          ],
        );
      },
    );
  }

  Widget _buildGroupedGridView(
      BuildContext context,
      WidgetRef ref,
      List<Product> flatSortedProducts,
      Map<String, List<Product>> groupedProducts,
      List<String> orderedGroupNames,
      AppThemeData theme) {
    return CustomScrollView(
      slivers: [
        for (final groupName in orderedGroupNames) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              // Pass context to the helper
              child: _buildGroupHeader(groupName, theme, context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 24.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0, childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final product = groupedProducts[groupName]![index];
                  return ShoppingListItemTile(
                    product: product,
                    allProductsInList: flatSortedProducts,
                    isGridView: true,
                  );
                },
                childCount: groupedProducts[groupName]!.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupedListView(
      BuildContext context,
      WidgetRef ref,
      List<Product> flatSortedProducts,
      Map<String, List<Product>> groupedProducts,
      List<String> orderedGroupNames,
      AppThemeData theme) {
    return CustomScrollView(
      slivers: [
        for (final groupName in orderedGroupNames) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              // Pass context to the helper
              child: _buildGroupHeader(groupName, theme, context),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final product = groupedProducts[groupName]![index];
                return ShoppingListItemTile(
                  product: product,
                  allProductsInList: flatSortedProducts,
                  isGridView: false,
                );
              },
              childCount: groupedProducts[groupName]!.length,
            ),
          ),
        ],
      ],
    );
  }

  // --- FULLY RESTORED AND CORRECTED _buildGroupHeader METHOD ---
  Widget _buildGroupHeader(String groupFirestoreName, AppThemeData theme, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Use the service method that takes the raw ID and returns a fully localized style object
    final style = CategoryService.getLocalizedStyleForGroupingName(groupFirestoreName, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            style.iconAssetPath, height: 20, width: 20,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 8),
          Text(
            style.displayName, // This is now the correctly translated name
            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}