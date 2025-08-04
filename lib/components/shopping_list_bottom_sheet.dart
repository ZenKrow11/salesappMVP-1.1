//lib/components/shopping_list_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/named_list.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/theme_color.dart';

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

  // This boolean clearly defines the two behaviors of the sheet.
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

  // A single, unified method to handle adding a product to a list and closing the sheet.
  // This is called from both the "Select List" and "New List" tabs.
  void _addAndDismiss(String listName) {
    if (widget.product == null) return; // Should not happen in this flow

    final trimmedName = listName.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('List name cannot be empty')),
      );
      return;
    }

    final notifier = ref.read(shoppingListsProvider.notifier);
    final currentLists = ref.read(shoppingListsProvider);

    // Check if we are creating a new list that already exists.
    bool isCreatingNew = !currentLists.any((list) => list.name == trimmedName);
    if (!isCreatingNew &&
        _newListController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('List with this name already exists')),
      );
      return;
    }

    // If the list is new, create it first.
    if (isCreatingNew) {
      notifier.addEmptyList(trimmedName);
    }

    // Add the product to the list (either existing or newly created).
    notifier.addToList(trimmedName, widget.product!);
    widget.onConfirm!(trimmedName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to "$trimmedName"')),
    );
    Navigator.of(context).pop();
  }

  // A unified method for creating a list when in "Select Active" mode.
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

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      // Use Padding with viewInsets to handle the keyboard automatically.
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
              // Adjusted height to better fit content without extra buttons.
              height: 250,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSelectList(shoppingLists, activeList),
                  _buildNewListTab(),
                ],
              ),
            ),
            // The confirmation actions are no longer needed, simplifying the UI.
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isSelectActiveMode ? 'Select or Create List' : 'Add to List',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        )
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.secondary,
      unselectedLabelColor: AppColors.inactive,
      indicatorColor: AppColors.secondary,
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'Select List'),
        Tab(text: 'New List'),
      ],
    );
  }

  Widget _buildSelectList(List<NamedList> lists, String? activeList) {
    if (lists.isEmpty) {
      return Center(
        child: Text(
          'No shopping lists yet.\nCreate one in the "New List" tab.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.inactive.withOpacity(0.8)),
        ),
      );
    }
    return ListView.builder(
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        final listName = list.name;
        // In "Select" mode, the active list is highlighted. In "Add" mode, no persistent selection is shown.
        final bool isCurrentlyActive =
            isSelectActiveMode && listName == activeList;

        return Opacity(
          opacity: isCurrentlyActive ? 1.0 : 0.7,
          child: Card(
            elevation: isCurrentlyActive ? 2 : 0,
            color: isCurrentlyActive
                ? AppColors.secondary.withOpacity(0.9)
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
                  isCurrentlyActive ? AppColors.primary : AppColors.inactive,
                ),
              ),
              onTap: () {
                if (isSelectActiveMode) {
                  // Flow 1: Just select the list and close.
                  ref
                      .read(activeShoppingListProvider.notifier)
                      .setActiveList(listName);
                  Navigator.pop(context);
                } else {
                  // Flow 2: Add the product to the selected list and close.
                  // This is the key change that removes the redundancy.
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        children: [
          TextField(
            controller: _newListController,
            autofocus: _tabController.index == 1,
            style: const TextStyle(color: AppColors.primary),
            // onSubmitted handles pressing 'enter' on the keyboard.
            onSubmitted: (listName) {
              if (isSelectActiveMode) {
                _createAndSetActive(listName);
              } else {
                _addAndDismiss(listName);
              }
            },
            decoration: InputDecoration(
              labelText: 'Enter new list name',
              labelStyle: const TextStyle(color: AppColors.inactive),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.inactive.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8.0)),
              focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.secondary),
                  borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
          const SizedBox(height: 20),
          // A dedicated button provides a clear call to action, which is better UX.
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
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
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}