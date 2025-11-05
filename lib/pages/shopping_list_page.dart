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
import 'package:sales_app_mvp/pages/manage_shopping_list.dart';

class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeListId = ref.watch(activeShoppingListProvider);
    final l10n = AppLocalizations.of(context)!;
    // We need to get the theme here to use it in the empty state.
    final theme = ref.watch(themeProvider);

    // ================================================================
    // === THIS ENTIRE BLOCK IS REPLACED FOR AESTHETIC CONSISTENCY ===
    // ================================================================
    if (activeListId == null) {
      return Scaffold(
        // 1. Set the background color to match the rest of the app.
        backgroundColor: theme.pageBackground,
        // 2. The redundant AppBar has been removed. The main screen's AppBar is used instead.
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.welcome, // Using l10n string
                  // 3. Style the text to be visible on a dark background.
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: theme.inactive,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.createFirstListPrompt, // Using l10n string
                  textAlign: TextAlign.center,
                  // 4. Style the text to be visible on a dark background.
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: theme.inactive.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.createListButton), // Using l10n string
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManageShoppingListsPage(),
                      ),
                    );
                  },
                  // 5. Style the button to match the primary action buttons elsewhere.
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.secondary,
                    foregroundColor: theme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // ================================================================
    // === END OF REPLACEMENT =========================================
    // ================================================================

    final asyncShoppingList = ref.watch(filteredAndSortedShoppingListProvider);
    final isGridView = ref.watch(settingsProvider).isGridView;

    return asyncShoppingList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text(l10n.errorLoadingList(err.toString()))),
      data: (products) {
        if (products.isEmpty) {
          final isFilterActive =
              ref.read(shoppingListPageFilterStateProvider).isFilterActive;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                isFilterActive
                    ? l10n.noProductsMatchFilter
                    : l10n.listIsEmpty, // This message is now for an existing, but empty, list.
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.inactive.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        final sortOption = ref.watch(shoppingListPageFilterStateProvider).sortOption;

        final Map<String, List<Product>> groupedProducts = groupBy(products, (Product p) => p.category);

        final List<String> orderedGroupNames = categoryDisplayOrder
            .where((name) => groupedProducts.containsKey(name))
            .toList();

        final List<Product> flatSortedProducts = orderedGroupNames
            .expand((groupName) => groupedProducts[groupName]!)
            .toList();

        return SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ScrollbarTheme(
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
                    child: isGridView
                        ? _buildGroupedGridView(
                      context,
                      flatSortedProducts,
                      groupedProducts,
                      orderedGroupNames,
                      theme,
                      sortOption,
                    )
                        : _buildGroupedListView(
                      context,
                      flatSortedProducts,
                      groupedProducts,
                      orderedGroupNames,
                      theme,
                      sortOption,
                    ),
                  ),
                ),
              ),
              ShoppingSummaryBar(products: products),
            ],
          ),
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
      SortOption sortOption,
      ) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
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
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 0.85,
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
      SortOption sortOption,
      ) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
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

  Widget _buildGroupHeader(
      String groupName,
      AppThemeData theme,
      BuildContext context,
      SortOption sortOption,
      ) {
    final l10n = AppLocalizations.of(context)!;
    final style = CategoryService.getLocalizedStyleForGroupingName(groupName, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            style.iconAssetPath,
            height: 24,
            width: 24,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          Text(
            style.displayName,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}