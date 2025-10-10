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
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/providers/settings_provider.dart';


class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncShoppingList = ref.watch(filteredAndSortedShoppingListProvider);
    final theme = ref.watch(themeProvider);
    final isGridView = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return asyncShoppingList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(l10n.errorLoadingList(err.toString()))),
      data: (products) {
        if (products.isEmpty) {
          final isFilterActive = ref.read(filterStateProvider).isFilterActiveForShoppingList;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                isFilterActive ? l10n.noProductsMatchFilter : l10n.listIsEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: theme.inactive.withOpacity(0.7), fontSize: 16),
              ),
            ),
          );
        }

        final sortOption = ref.watch(filterStateProvider).sortOption;

        final Map<String, List<Product>> groupedProducts;
        final List<String> orderedGroupNames;

        if (sortOption == SortOption.storeAlphabetical) {
          groupedProducts = groupBy(products, (Product p) => p.store);
          orderedGroupNames = groupedProducts.keys.toList()..sort();
        } else {
          groupedProducts = groupBy(products, (Product p) => p.category);
          orderedGroupNames = categoryDisplayOrder
              .where((name) => groupedProducts.containsKey(name))
              .toList();
        }

        final List<Product> flatSortedProducts = orderedGroupNames
            .expand((groupName) => groupedProducts[groupName]!)
            .toList();

        return Column(
          children: [
            Expanded(
              child: isGridView
                  ? _buildGroupedGridView(context, flatSortedProducts, groupedProducts, orderedGroupNames, theme, sortOption)
                  : _buildGroupedListView(context, flatSortedProducts, groupedProducts, orderedGroupNames, theme, sortOption),
            ),
            ShoppingSummaryBar(products: products),
          ],
        );
      },
    );
  }

  Widget _buildGroupedGridView(
      BuildContext context,
      List<Product> flatSortedProducts,
      Map<String, List<Product>> groupedProducts,
      List<String> orderedGroupNames,
      AppThemeData theme,
      SortOption sortOption) {
    return CustomScrollView(
      slivers: [
        for (final groupName in orderedGroupNames) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: _buildGroupHeader(groupName, theme, context, sortOption),
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
      List<Product> flatSortedProducts,
      Map<String, List<Product>> groupedProducts,
      List<String> orderedGroupNames,
      AppThemeData theme,
      SortOption sortOption) {
    return CustomScrollView(
      slivers: [
        for (final groupName in orderedGroupNames) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: _buildGroupHeader(groupName, theme, context, sortOption),
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

  Widget _buildGroupHeader(String groupName, AppThemeData theme, BuildContext context, SortOption sortOption) {
    if (sortOption == SortOption.storeAlphabetical) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.accent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Text(
          groupName,
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final style = CategoryService.getLocalizedStyleForGroupingName(groupName, l10n);

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
            style.displayName,
            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}