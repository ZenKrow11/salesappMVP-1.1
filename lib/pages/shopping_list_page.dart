// lib/pages/shopping_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grouped_list/grouped_list.dart';
// --- REFACTOR: OLD IMPORT REMOVED ---
// import 'package:sales_app_mvp/components/add_custom_item_dialog.dart';
import 'package:sales_app_mvp/components/bottom_summary_bar.dart';
// --- REFACTOR: NEW IMPORTS ADDED ---
import 'package:sales_app_mvp/components/custom_item_storage_view.dart';
import 'package:sales_app_mvp/pages/create_custom_item_page.dart';
// --- (end of new imports) ---
import 'package:sales_app_mvp/components/management_list_item_tile.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'package:sales_app_mvp/pages/shopping_mode_screen.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

// --- REFACTOR: Converted to ConsumerStatefulWidget to manage view state ---
class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  // --- REFACTOR: Added state variable to toggle between views ---
  bool _isShowingCustomStorage = false;

  @override
  Widget build(BuildContext context) {
    final init = ref.watch(initializationProvider);
    final theme = ref.watch(themeProvider);
    final scaffoldKey = GlobalKey<ScaffoldState>();

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
        key: scaffoldKey,
        backgroundColor: theme.pageBackground,
        endDrawer: _buildDrawer(context, ref),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, ref, scaffoldKey),
              Expanded(
                child: _buildBodyContent(context, ref),
              ),
              // Show summary bar only when viewing a shopping list
              if (!_isShowingCustomStorage) _buildSummaryBar(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
    final activeListId = ref.watch(activeShoppingListProvider);
    final allListsAsync = ref.watch(allShoppingListsProvider);

    bool isDefaultList = true;

    allListsAsync.whenData((lists) {
      final activeList = lists.firstWhere(
            (list) => list.id == activeListId,
        orElse: () => ShoppingListInfo(id: '', name: merklisteListName),
      );
      isDefaultList = activeList.name == merklisteListName;
    });

    return Drawer(
      backgroundColor: theme.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.primary),
            child: Text(
              'List Options',
              style: TextStyle(
                color: theme.secondary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // --- REFACTOR: Added a button to go back to the shopping list view ---
          if (_isShowingCustomStorage)
            ListTile(
              title: Text('Back to Shopping List', style: TextStyle(color: theme.inactive)),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _isShowingCustomStorage = false;
                });
              },
            ),
          ListTile(
            title: Text('Start Shopping Mode', style: TextStyle(color: theme.inactive)),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ShoppingModeScreen()),
              );
            },
          ),
          ListTile(
            title: Text('Add New List',
                style: TextStyle(
                  color: isPremium ? theme.inactive : theme.inactive.withOpacity(0.5),
                )),
            onTap: () {
              Navigator.of(context).pop();
              if (isPremium) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const ShoppingListBottomSheet(initialTabIndex: 1),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Creating multiple lists is a Premium Feature!'),
                    action: SnackBarAction(
                      label: 'UPGRADE',
                      onPressed: () {
                        context.findAncestorStateOfType<MainAppScreenState>()?.navigateToTab(2);
                      },
                    ),
                  ),
                );
              }
            },
          ),
          // --- REFACTOR: Drawer options updated for new custom item flow ---
          const Divider(),
          ListTile(
            title: Text('My Custom Items', style: TextStyle(color: theme.inactive)),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              setState(() {
                _isShowingCustomStorage = true;
              });
            },
          ),
          ListTile(
            title: Text('Create New Custom Item', style: TextStyle(color: theme.inactive)),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CreateCustomItemPage(),
              ));
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: isDefaultList || _isShowingCustomStorage
                  ? theme.inactive.withOpacity(0.5)
                  : Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete Current List',
              style: TextStyle(
                color: isDefaultList || _isShowingCustomStorage
                    ? theme.inactive.withOpacity(0.5)
                    : Theme.of(context).colorScheme.error,
              ),
            ),
            // Disable delete button when not viewing a deletable list
            onTap: isDefaultList || _isShowingCustomStorage
                ? null
                : () {
              Navigator.pop(context);
              _showDeleteConfirmationDialog(context, ref, activeListId);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, String listId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete List?'),
          content: const Text(
              'Are you sure you want to permanently delete this list and all of its items? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref.read(firestoreServiceProvider).deleteList(listId: listId);
                  await ref.read(activeShoppingListProvider.notifier).setActiveList(merklisteListName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('List deleted successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting list: ${e.toString()}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- REFACTOR: Header now conditionally changes based on the view ---
  Widget _buildHeader(BuildContext context, WidgetRef ref, GlobalKey<ScaffoldState> scaffoldKey) {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Row(
        children: [
          Expanded(
            child: _isShowingCustomStorage
                ? Text( // Header for Custom Items view
              'My Custom Items',
              style: TextStyle(
                color: theme.inactive,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            )
                : isPremium // Original Header for Shopping List view
                ? _buildPremiumHeaderDropdown(ref, theme)
                : _buildFreeUserHeader(context, theme),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: theme.inactive, size: 26),
            onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
    );
  }

  // --- REFACTOR: Body now conditionally shows Custom Storage or Shopping List ---
  Widget _buildBodyContent(BuildContext context, WidgetRef ref) {
    // If true, show the new custom item storage view
    if (_isShowingCustomStorage) {
      return const CustomItemStorageView();
    }

    // Otherwise, show the existing shopping list view
    final asyncShoppingList = ref.watch(shoppingListWithDetailsProvider);
    final theme = ref.watch(themeProvider);

    return asyncShoppingList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading list: $err',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.inactive),
          ),
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
                  color: theme.inactive.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ),
          );
        } else {
          return _buildGroupedListView(context, ref, products, theme);
        }
      },
    );
  }

  // --- NO CHANGES to the methods below this line ---

  Widget _buildPremiumHeaderDropdown(WidgetRef ref, AppThemeData theme) {
    final allListsAsync = ref.watch(allShoppingListsProvider);
    final activeListId = ref.watch(activeShoppingListProvider);

    return allListsAsync.when(
      loading: () => Text(
        activeListId,
        style: TextStyle(color: theme.inactive, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      error: (e, s) => Text('Error', style: TextStyle(color: Colors.red, fontSize: 24)),
      data: (lists) {
        if (lists.isEmpty) {
          return Text('Loading List...',
              style: TextStyle(color: theme.inactive, fontSize: 24, fontWeight: FontWeight.bold));
        }
        final activeListExists = lists.any((list) => list.id == activeListId);
        if (!activeListExists) {
          return Text(activeListId,
              style: TextStyle(color: theme.inactive, fontSize: 24, fontWeight: FontWeight.bold));
        }
        return DropdownButton<String>(
          value: activeListId,
          onChanged: (newListId) {
            if (newListId != null) {
              ref.read(activeShoppingListProvider.notifier).setActiveList(newListId);
            }
          },
          underline: const SizedBox.shrink(),
          icon: Icon(Icons.arrow_drop_down, color: theme.inactive, size: 28),
          style: TextStyle(color: theme.inactive, fontSize: 24, fontWeight: FontWeight.bold),
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

  Widget _buildGroupedListView(BuildContext context, WidgetRef ref, List<Product> products, AppThemeData theme) {
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);
    return GroupedListView<Product, String>(
      elements: products,
      groupBy: (product) => CategoryService.getGroupingDisplayNameForProduct(product),
      useStickyGroupSeparators: true,
      stickyHeaderBackgroundColor: theme.pageBackground,
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
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
      itemBuilder: (context, product) {
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

  Widget _buildFreeUserHeader(BuildContext context, AppThemeData theme) {
    return InkWell(
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
          Icon(Icons.arrow_drop_down, color: theme.inactive.withOpacity(0.5), size: 28),
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