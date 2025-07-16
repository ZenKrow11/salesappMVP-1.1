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
  String? _selectedList;
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

  @override
  Widget build(BuildContext context) {
    final shoppingLists = ref.watch(shoppingListsProvider);
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);
    final activeList = ref.watch(activeShoppingListProvider);

    // This Container provides the background color and rounded corners,
    // making the widget self-contained and visually consistent.
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
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
              height: 220,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSelectList(shoppingLists, activeList),
                  _buildNewListTab(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!isSelectActiveMode) ...[
              _buildConfirmActions(shoppingListNotifier),
              const SizedBox(height: 10),
            ]
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
      return const Center(
        child: Text(
          'No shopping lists yet.\nCreate one in the "New List" tab.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.inactive),
        ),
      );
    }
    return ListView.builder(
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        final listName = list.name;
        final bool isCurrentlyActive =
        isSelectActiveMode ? listName == activeList : listName == _selectedList;

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
                  ref
                      .read(activeShoppingListProvider.notifier)
                      .setActiveList(listName);
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _newListController.clear();
                    _selectedList = listName;
                  });
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _newListController,
        autofocus: _tabController.index == 1,
        style: const TextStyle(color: AppColors.primary),
        onSubmitted: (listName) {
          if (isSelectActiveMode) {
            _onCreateAndSetActive(listName);
          }
        },
        decoration: InputDecoration(
          labelText: 'Create new list name',
          labelStyle: const TextStyle(color: AppColors.inactive),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.inactive.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8.0)),
          focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.secondary),
              borderRadius: BorderRadius.circular(8.0)),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && _selectedList != null) {
            setState(() => _selectedList = null);
          }
        },
      ),
    );
  }

  Widget _buildConfirmActions(ShoppingListNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.inactive),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL',
                style: TextStyle(
                    color: AppColors.inactive, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _onConfirmAddPressed(notifier),
            child: const Text('CONFIRM',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _onCreateAndSetActive(String listName) {
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

  void _onConfirmAddPressed(ShoppingListNotifier notifier) {
    final newListName = _newListController.text.trim();
    final listName = newListName.isNotEmpty ? newListName : _selectedList;
    final currentLists = ref.read(shoppingListsProvider);

    if (listName == null || listName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a list name')),
      );
      return;
    }

    if (newListName.isNotEmpty &&
        currentLists.any((list) => list.name == listName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('List name already exists')),
      );
      return;
    }

    if (newListName.isNotEmpty) {
      notifier.addEmptyList(listName);
    }

    notifier.addToList(listName, widget.product!);
    widget.onConfirm!(listName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to "$listName"')),
    );
    Navigator.of(context).pop();
  }
}