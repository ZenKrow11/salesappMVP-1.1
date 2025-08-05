import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/named_list.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/app_theme.dart'; // UPDATED Import

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
  late TabController _tabController;

  bool get isSelectActiveMode => widget.product == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _newListController.dispose();
    _tabController.dispose();
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
    final shoppingLists = ref.watch(shoppingListsProvider);
    final activeList = ref.watch(activeShoppingListProvider);
    // Get theme from Riverpod provider
    final theme = ref.watch(themeProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.background, // UPDATED
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
            SizedBox(
              height: 250,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSelectList(shoppingLists, activeList),
                  _buildNewListTab(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = ref.watch(themeProvider); // Get theme
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isSelectActiveMode ? 'Select or Create List' : 'Add to List',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.secondary), // UPDATED
        ),
        IconButton(
          icon: Icon(Icons.close, color: theme.accent), // UPDATED
          onPressed: () => Navigator.pop(context),
        )
      ],
    );
  }

  Widget _buildTabBar() {
    final theme = ref.watch(themeProvider); // Get theme
    return TabBar(
      controller: _tabController,
      labelColor: theme.secondary, // UPDATED
      unselectedLabelColor: theme.inactive, // UPDATED
      indicatorColor: theme.secondary, // UPDATED
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'Select List'),
        Tab(text: 'New List'),
      ],
    );
  }

  Widget _buildSelectList(List<NamedList> lists, String? activeList) {
    final theme = ref.watch(themeProvider); // Get theme
    if (lists.isEmpty) {
      return Center(
        child: Text(
          'No shopping lists yet.\nCreate one in the "New List" tab.',
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.inactive.withOpacity(0.8)), // UPDATED
        ),
      );
    }
    return ListView.builder(
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        final listName = list.name;
        final bool isCurrentlyActive =
            isSelectActiveMode && listName == activeList;

        return Opacity(
          opacity: isCurrentlyActive ? 1.0 : 0.7,
          child: Card(
            elevation: isCurrentlyActive ? 2 : 0,
            color: isCurrentlyActive
                ? theme.secondary.withOpacity(0.9) // UPDATED
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
                  isCurrentlyActive ? theme.primary : theme.inactive, // UPDATED
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
    final theme = ref.watch(themeProvider); // Get theme
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        children: [
          TextField(
            controller: _newListController,
            autofocus: _tabController.index == 1,
            // UPDATED: Changed text color to be light for readability on a dark background
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
              labelStyle: TextStyle(color: theme.inactive), // UPDATED
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.inactive.withOpacity(0.5)), // UPDATED
                  borderRadius: BorderRadius.circular(8.0)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.secondary), // UPDATED
                  borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.secondary, // UPDATED
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
                  color: theme.primary, fontWeight: FontWeight.bold), // UPDATED
            ),
          ),
        ],
      ),
    );
  }
}