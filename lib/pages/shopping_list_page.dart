// lib/pages/shopping_list_page.dart

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

// No longer needed
// import 'package:sales_app_mvp/components/management_grid_tile.dart';
import 'package:sales_app_mvp/components/shopping_list_item_tile.dart';
import 'package:sales_app_mvp/components/shopping_summary_bar.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
    final theme = ref.watch(themeProvider);
    final isGridView = ref.watch(shoppingListViewModeProvider);

    return asyncShoppingList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading list: $err')),
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'This list is empty.\nDouble-tap an item on the sales page to add it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: theme.inactive.withOpacity(0.7), fontSize: 16),
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: isGridView
                  ? _buildGroupedGridView(context, ref, products, theme)
                  : _buildGroupedListView(context, ref, products, theme),
            ),
            ShoppingSummaryBar(products: products),
          ],
        );
      },
    );
  }

  Widget _buildGroupedGridView(BuildContext context, WidgetRef ref,
      List<Product> products, AppThemeData theme) {
    final groupedProducts = groupBy(products, (Product p) => CategoryService.getGroupingDisplayNameForProduct(p));
    final orderedGroupNames = categoryDisplayOrder.where((name) => groupedProducts.containsKey(name)).toList();

    return CustomScrollView(
      slivers: [
        for (final groupName in orderedGroupNames) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: _buildGroupHeader(groupName, theme),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 24.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 0.8, // Aspect ratio can be adjusted if needed
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final product = groupedProducts[groupName]![index];
                  // --- FIX: Use the unified tile with isGridView set to true ---
                  return ShoppingListItemTile(
                    product: product,
                    allProductsInList: products,
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

  Widget _buildGroupedListView(BuildContext context, WidgetRef ref,
      List<Product> products, AppThemeData theme) {
    final groupedProducts = groupBy(products, (Product p) => CategoryService.getGroupingDisplayNameForProduct(p));
    final orderedGroupNames = categoryDisplayOrder.where((name) => groupedProducts.containsKey(name)).toList();

    return CustomScrollView(
      slivers: [
        for (final groupName in orderedGroupNames) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: _buildGroupHeader(groupName, theme),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final product = groupedProducts[groupName]![index];
                // --- FIX: Use the unified tile with isGridView set to false ---
                return ShoppingListItemTile(
                  product: product,
                  allProductsInList: products,
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

  Widget _buildGroupHeader(String groupName, AppThemeData theme) {
    final style = CategoryService.getStyleForGroupingName(groupName);
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
            style.iconAssetPath,
            height: 20,
            width: 20,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 8),
          Text(
            groupName,
            style: const TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}