// lib/pages/shopping_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:sales_app_mvp/components/bottom_summary_bar.dart';
import 'package:sales_app_mvp/components/management_list_item_tile.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'shopping_mode_screen.dart';

import 'main_app_screen.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
    final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.pageBackground,
      endDrawer: _buildDrawer(context, ref, isPremium), // FIXED: Now passes `context`
      floatingActionButton: null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ref, scaffoldKey),
            Expanded(
              child: asyncShoppingList.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading list: $err')),
                data: (products) {
                  return _buildMerklisteView(context, ref, products, theme: theme);
                },
              ),
            ),
            asyncShoppingList.when(
              data: (products) => BottomSummaryBar(products: products),
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, GlobalKey<ScaffoldState> scaffoldKey) {
    final theme = ref.watch(themeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Managing multiple lists is a Premium Feature!')),
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
                  Icon(Icons.arrow_drop_down, color: theme.inactive, size: 28),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: theme.inactive, size: 26),
            onPressed: () {
              scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, bool isPremium) {
    final theme = ref.watch(themeProvider);
    return Drawer(
      backgroundColor: theme.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.primary),
            child: Text(
              'List Options',
              style: TextStyle(color: theme.secondary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(Icons.playlist_add, color: isPremium ? theme.inactive : theme.inactive.withOpacity(0.5)),
            title: Text('Add New List', style: TextStyle(color: isPremium ? theme.inactive : theme.inactive.withOpacity(0.5))),
            // --- MODIFICATION START ---
            onTap: () {
              // First, close the drawer.
              Navigator.of(context).pop();

              if (isPremium) {
                // If the user is premium, we would show the "create new list" dialog.
                // For now, a simple message is fine.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium feature: Create new list!')),
                );
              } else {
                // If the user is NOT premium, show the upgrade message.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Creating multiple lists is a Premium Feature!'),
                    action: SnackBarAction(
                      label: 'UPGRADE',
                      onPressed: () {
                        // Navigate to the Account Page (Tab 2)
                        final mainAppScreenState = context.findAncestorStateOfType<MainAppScreenState>();
                        mainAppScreenState?.navigateToTab(2);
                      },
                    ),
                  ),
                );
              }
            },
            // --- MODIFICATION END ---
          ),
          ListTile(
            leading: Icon(Icons.add_shopping_cart, color: theme.inactive),
            title: Text('Add Custom Item', style: TextStyle(color: theme.inactive)),
            onTap: () {
              // Placeholder for future functionality
            },
          ),
          ListTile(
            leading: Icon(Icons.checklist, color: theme.inactive),
            title: Text('Start Shopping Mode', style: TextStyle(color: theme.inactive)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ShoppingModeScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // MODIFIED: Final version of the list view builder.
  Widget _buildMerklisteView(BuildContext context, WidgetRef ref, List<Product> products, {required AppThemeData theme}) {
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Your list is empty.\nDouble-tap an item on the main page to add it!',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.inactive.withOpacity(0.7), fontSize: 16),
          ),
        ),
      );
    }

    return GroupedListView<Product, String>(
      elements: products,
      groupBy: (product) => CategoryService.getGroupingDisplayNameForProduct(product),

      // --- FINAL FIXES APPLIED HERE ---
      useStickyGroupSeparators: true,
      stickyHeaderBackgroundColor: theme.pageBackground, // Sets the correct background for the sticky header
      // --- END OF FIXES ---

      groupSeparatorBuilder: (String groupName) {
        final style = CategoryService.getStyleForGroupingName(groupName);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Container(
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
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      itemBuilder: (context, product) {
        // Now that the tile has its own solid background, this will work perfectly.
        return ManagementListItemTile(
          product: product,
          allProductsInList: products,
          onDoubleTap: () {
            shoppingListNotifier.removeItemFromList(product);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Removed "${product.name}"'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        );
      },
      itemComparator: (item1, item2) => item1.name.compareTo(item2.name),
      order: GroupedListOrder.ASC,
    );
  }
}