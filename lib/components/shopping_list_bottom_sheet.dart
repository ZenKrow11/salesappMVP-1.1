// lib/components/shopping_list_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/named_list.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/app_theme.dart';
import '../providers/user_profile_provider.dart';
import '../pages/main_app_screen.dart';
import '../providers/app_data_provider.dart';

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

    // Ensure shopping lists are initialized when the bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shoppingListsProvider.notifier).ensureInitialized();
    });
  }

  @override
  void dispose() {
    _newListController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _addAndDismiss(String listName) {
    if (widget.product == null) return;

    final trimmedName = listName.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('List name cannot be empty')),
      );
      return;
    }

    final notifier = ref.read(shoppingListsProvider.notifier);
    final currentLists = ref.read(shoppingListsProvider);

    bool isCreatingNew = !currentLists.any((list) => list.name == trimmedName);
    if (!isCreatingNew &&
        _newListController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('List with this name already exists')),
      );
      return;
    }

    if (isCreatingNew) {
      notifier.addEmptyList(trimmedName);
    }

    notifier.addToList(trimmedName, widget.product!);
    widget.onConfirm!(trimmedName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to "$trimmedName"')),
    );
    Navigator.of(context).pop();
  }

  void _createAndSetActive(String listName) {
    final trimmedName = listName.trim();
    if (trimmedName.isEmpty) return;

    final notifier = ref.read(shoppingListsProvider.notifier);
    final currentLists = ref.read(shoppingListsProvider);

    if (currentLists.any((list) => list.name == trimmedName)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('List name already exists')));
      return;
    }

    notifier.addEmptyList(trimmedName);
    ref.read(activeShoppingListProvider.notifier).setActiveList(trimmedName);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created and selected "$trimmedName"')));
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

  Widget _buildTabContent() {
    // Watch both the app status AND the shopping lists
    final appStatus = ref.watch(appDataProvider.select((data) => data.status));
    final shoppingLists = ref.watch(shoppingListsProvider);
    final activeList = ref.watch(activeShoppingListProvider);

    // Show loading if app isn't loaded OR if shopping lists are empty when they shouldn't be
    bool isLoading = appStatus != InitializationStatus.loaded;

    // Additional check: if app is loaded but no lists exist (including Merkliste), we're still initializing
    if (!isLoading && shoppingLists.isEmpty) {
      isLoading = true;
    }

    // Additional check: if app is loaded but Merkliste doesn't exist, we're still initializing
    if (!isLoading && !shoppingLists.any((list) => list.name == merklisteListName)) {
      isLoading = true;
    }

    if (isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 250,
      child: TabBarView(
        controller: _tabController!,
        children: [
          _buildSelectList(shoppingLists, activeList),
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
      onTap: null,
    );
  }

  Widget _buildSelectList(List<NamedList> lists, String? activeList) {
    final theme = ref.watch(themeProvider);

    // This should not happen anymore due to our loading checks above
    if (lists.isEmpty) {
      return Center(
        child: Text(
          'No shopping lists available.',
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.inactive.withOpacity(0.8)),
        ),
      );
    }

    // Sort lists to ensure Merkliste appears first
    final sortedLists = [...lists];
    sortedLists.sort((a, b) {
      if (a.name == merklisteListName) return -1;
      if (b.name == merklisteListName) return 1;
      return a.index.compareTo(b.index);
    });

    return ListView.builder(
      itemCount: sortedLists.length,
      itemBuilder: (context, index) {
        final list = sortedLists[index];
        final listName = list.name;
        final bool isCurrentlyActive =
            isSelectActiveMode && listName == activeList;

        return Opacity(
          opacity: isCurrentlyActive ? 1.0 : 0.7,
          child: Card(
            elevation: isCurrentlyActive ? 2 : 0,
            color: isCurrentlyActive
                ? theme.secondary.withOpacity(0.9)
                : Colors.transparent,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              title: Text(
                listName,
                style: TextStyle(
                  fontWeight:
                  isCurrentlyActive ? FontWeight.bold : FontWeight.normal,
                  color:
                  isCurrentlyActive ? theme.primary : theme.inactive,
                ),
              ),
              onTap: () {
                if (isSelectActiveMode) {
                  ref
                      .read(activeShoppingListProvider.notifier)
                      .setActiveList(listName);
                  Navigator.pop(context);
                } else {
                  _addAndDismiss(listName);
                }
              },
            ),
          ),
        );
      },
    );
  }

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
                  _addAndDismiss(listName);
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
                  _addAndDismiss(listName);
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