// lib/pages/shopping_list_page.dart

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sales_app_mvp/components/bottom_summary_bar.dart';
import 'package:sales_app_mvp/components/management_grid_tile.dart';
import 'package:sales_app_mvp/components/list_options_bottom_sheet.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

// --- REFACTOR: This can now be a simpler ConsumerWidget ---
class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(initializationProvider);
    final theme = ref.watch(themeProvider);

    return init.when(
      loading: () => Scaffold(
        backgroundColor: theme.pageBackground,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: theme.pageBackground,
        body: Center(child: Text('Fatal Error: $err')),
      ),
      data: (_) => Scaffold(
        backgroundColor: theme.pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, ref),
              Expanded(
                child: _buildBodyContent(context, ref),
              ),
              // The summary bar is now always visible on this page.
              _buildSummaryBar(ref),
            ],
          ),
        ),
      ),
    );
  }

  // --- REFACTOR: Simplified header, no longer needs scaffoldKey for a drawer ---
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Row(
        children: [
          Expanded(
            child: isPremium
                ? _buildPremiumHeaderDropdown(ref, theme)
                : _buildFreeUserHeader(context, theme),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: theme.inactive, size: 26),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ListOptionsBottomSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- REFACTOR: Simplified body content, it no longer toggles views ---
  Widget _buildBodyContent(BuildContext context, WidgetRef ref) {
    final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
    final theme = ref.watch(themeProvider);

    return asyncShoppingList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading list: $err',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.inactive)),
        ),
      ),
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
        } else {
          return _buildGroupedGridView(context, ref, products, theme);
        }
      },
    );
  }

  // --- The rest of the file contains the helper methods ---

  Widget _buildGroupedGridView(BuildContext context, WidgetRef ref,
      List<Product> products, AppThemeData theme) {
    final groupedProducts = groupBy(
        products, (Product p) => CategoryService.getGroupingDisplayNameForProduct(p));
    final orderedGroupNames = categoryDisplayOrder
        .where((name) => groupedProducts.containsKey(name))
        .toList();

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
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final product = groupedProducts[groupName]![index];
                  return ManagementGridTile(
                    product: product,
                    allProductsInList: products,
                    onDoubleTap: () {
                      ref
                          .read(shoppingListsProvider.notifier)
                          .removeItemFromList(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed "${product.name}"'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
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

  Widget _buildPremiumHeaderDropdown(WidgetRef ref, AppThemeData theme) {
    final allListsAsync = ref.watch(allShoppingListsProvider);
    final activeListId = ref.watch(activeShoppingListProvider);

    return allListsAsync.when(
      loading: () => Text(
        activeListId,
        style: TextStyle(
            color: theme.inactive, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      error: (e, s) => Text('Error', style: TextStyle(color: Colors.red, fontSize: 24)),
      data: (lists) {
        if (lists.isEmpty) {
          return Text('Loading List...',
              style: TextStyle(
                  color: theme.inactive,
                  fontSize: 24,
                  fontWeight: FontWeight.bold));
        }
        final activeListExists = lists.any((list) => list.id == activeListId);
        if (!activeListExists) {
          return Text(activeListId,
              style: TextStyle(
                  color: theme.inactive,
                  fontSize: 24,
                  fontWeight: FontWeight.bold));
        }
        return DropdownButton<String>(
          value: activeListId,
          onChanged: (newListId) {
            if (newListId != null) {
              ref
                  .read(activeShoppingListProvider.notifier)
                  .setActiveList(newListId);
            }
          },
          underline: const SizedBox.shrink(),
          icon: Icon(Icons.arrow_drop_down, color: theme.inactive, size: 28),
          style: TextStyle(
              color: theme.inactive, fontSize: 24, fontWeight: FontWeight.bold),
          dropdownColor: theme.background,
          items: lists.map<DropdownMenuItem<String>>((ShoppingListInfo list) {
            return DropdownMenuItem<String>(
              value: list.id,
              child: Text(list.name),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFreeUserHeader(BuildContext context, AppThemeData theme) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Managing multiple lists is a Premium Feature!')),
        );
      },
      child: Row(
        children: [
          Text(
            merklisteListName,
            style: TextStyle(
              color: theme.inactive,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down,
              color: theme.inactive.withOpacity(0.5), size: 28),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(WidgetRef ref) {
    final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
    return asyncShoppingList.when(
      data: (products) => BottomSummaryBar(products: products),
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}