// lib/components/shopping_list_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
// REMOVED: No longer need NamedList
import '../providers/shopping_list_provider.dart';
import '../widgets/app_theme.dart';
import '../providers/user_profile_provider.dart';
import '../pages/main_app_screen.dart';
// REMOVED: No longer need app_data_provider for loading state

class ShoppingListBottomSheet extends ConsumerStatefulWidget {
  final Product? product;
  final void Function(String selectedListName)? onConfirm;
  final int initialTabIndex;

  const ShoppingListBottomSheet({
    super.key,
    this.product,
    this.onConfirm,
    this.initialTabIndex = 0,
  }) : assert(product == null || onConfirm != null,
  'onConfirm must be provided when a product is given');

  @override
  ConsumerState<ShoppingListBottomSheet> createState() =>
      _ShoppingListBottomSheetState();
}

class _ShoppingListBottomSheetState
    extends ConsumerState<ShoppingListBottomSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _newListController = TextEditingController();
  TabController? _tabController;

  bool get isSelectActiveMode => widget.product == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    // REMOVED: Initialization is now handled automatically by the provider itself.
  }

  @override
  void dispose() {
    _newListController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  // --- MODIFICATION: Simplified add/dismiss logic for free tier ---
  void _addAndDismiss() {
    if (widget.product == null) return;

    final notifier = ref.read(shoppingListsProvider.notifier);
    notifier.addToList(widget.product!);
    widget.onConfirm!(merklisteListName); // Confirm with the hardcoded list name

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to "Merkliste"')),
    );
    Navigator.of(context).pop();
  }

  // REWRITE THIS METHOD
  void _createAndSetActive(String listName) {
    if (listName.trim().isEmpty) {
      // Don't create a list with an empty name
      return;
    }
    final trimmedName = listName.trim();
    // Call the new notifier method
    ref.read(shoppingListsProvider.notifier).createNewList(trimmedName);

    Navigator.of(context).pop(); // Close the bottom sheet

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created and selected list "$trimmedName"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildTabBar(),
            const SizedBox(height: 16),
            _buildTabContent(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- MODIFICATION: Tab content no longer needs complex loading logic ---
  Widget _buildTabContent() {
    // The UI is simple enough now that we don't need to watch any providers here.
    // The sub-widgets will handle their own state.
    return SizedBox(
      height: 250,
      child: TabBarView(
        controller: _tabController!,
        children: [
          _buildSelectList(),
          _buildNewListTab(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = ref.watch(themeProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isSelectActiveMode ? 'Select or Create List' : 'Add to List',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.secondary),
        ),
        IconButton(
          icon: Icon(Icons.close, color: theme.accent),
          onPressed: () => Navigator.pop(context),
        )
      ],
    );
  }

  Widget _buildTabBar() {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;

    return TabBar(
      controller: _tabController!,
      labelColor: theme.secondary,
      unselectedLabelColor: theme.inactive,
      indicatorColor: theme.secondary,
      dividerColor: Colors.transparent,
      tabs: [
        const Tab(text: 'Select List'),
        Tab(
          child: Text(
            'New List',
            style: TextStyle(
              color: isPremium ? theme.secondary : theme.inactive.withOpacity(0.5),
            ),
          ),
        ),
      ],
      onTap: null, // Let the tab controller handle it
    );
  }

  // REWRITE THIS METHOD
  Widget _buildSelectList() {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
    final activeListId = ref.watch(activeShoppingListProvider);

    // --- PATH FOR FREE USERS ---
    // If the user is not premium, we don't need to fetch lists.
    // We just show them their one and only "Merkliste".
    if (!isPremium) {
      const listName = merklisteListName;
      final bool isCurrentlyActive = listName == activeListId;

      return ListView(
        children: [
          Opacity(
            opacity: isCurrentlyActive ? 1.0 : 0.7,
            child: Card(
              elevation: isCurrentlyActive ? 2 : 0,
              color: isCurrentlyActive
                  ? theme.secondary.withOpacity(0.9)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                title: Text(
                  listName,
                  style: TextStyle(
                    fontWeight: isCurrentlyActive ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentlyActive ? theme.primary : theme.inactive,
                  ),
                ),
                onTap: () {
                  if (isSelectActiveMode) {
                    ref.read(activeShoppingListProvider.notifier).setActiveList(listName);
                    Navigator.pop(context);
                  } else {
                    _addAndDismiss();
                  }
                },
              ),
            ),
          ),
        ],
      );
    }

    // --- PATH FOR PREMIUM USERS ---
    // Premium users will see a dynamic list of all their created lists.
    final allListsAsync = ref.watch(allShoppingListsProvider);

    return allListsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (lists) {
        // This check handles the brief moment before "Merkliste" is created.
        if (lists.isEmpty) {
          return const Center(child: Text('Your default list is being prepared...'));
        }
        return ListView.builder(
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            final isCurrentlyActive = isSelectActiveMode && list.id == activeListId;

            return Opacity(
              opacity: isCurrentlyActive ? 1.0 : 0.7,
              child: Card(
                elevation: isCurrentlyActive ? 2 : 0,
                color: isCurrentlyActive
                    ? theme.secondary.withOpacity(0.9)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  title: Text(
                    list.name,
                    style: TextStyle(
                      fontWeight: isCurrentlyActive ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentlyActive ? theme.primary : theme.inactive,
                    ),
                  ),
                  onTap: () {
                    if (isSelectActiveMode) {
                      ref.read(activeShoppingListProvider.notifier).setActiveList(list.id);
                      Navigator.pop(context);
                    } else {
                      // This part would need a premium-specific implementation
                      // to choose which list to add a product to.
                      _addAndDismiss(); // For now, it defaults to the active list.
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // This premium-focused tab is unchanged.
  Widget _buildNewListTab() {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;

    if (isPremium) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          children: [
            TextField(
              controller: _newListController,
              autofocus: _tabController?.index == 1,
              style: TextStyle(color: theme.inactive),
              onSubmitted: (listName) {
                if (isSelectActiveMode) {
                  _createAndSetActive(listName);
                } else {
                  // This branch would need refactoring for premium
                }
              },
              decoration: InputDecoration(
                labelText: 'Enter new list name',
                labelStyle: TextStyle(color: theme.inactive),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.inactive.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8.0)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.secondary),
                    borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final listName = _newListController.text;
                if (isSelectActiveMode) {
                  _createAndSetActive(listName);
                } else {
                  // This branch would need refactoring for premium
                }
              },
              child: Text(
                isSelectActiveMode ? 'CREATE AND SELECT' : 'CREATE AND ADD',
                style: TextStyle(
                    color: theme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 48, color: theme.inactive.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'Create unlimited custom lists with Premium.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: theme.inactive),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.secondary),
              onPressed: () {
                Navigator.of(context).pop();
                final mainAppScreenState = context.findAncestorStateOfType<MainAppScreenState>();
                mainAppScreenState?.navigateToTab(2);
              },
              child: Text('Upgrade Now', style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }
}