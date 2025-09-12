// lib/components/shopping_list_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/shopping_list_info.dart';
import '../providers/shopping_list_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/app_theme.dart';
import '../providers/user_profile_provider.dart';
import '../pages/main_app_screen.dart';

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
  }

  @override
  void dispose() {
    _newListController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _addAndDismiss() {
    if (widget.product == null) return;
    ref.read(shoppingListsProvider.notifier).addToList(widget.product!);
    widget.onConfirm!(merklisteListName);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to "Merkliste"')),
    );
    Navigator.of(context).pop();
  }

  void _createAndSetActive(String listName) {
    if (listName.trim().isEmpty) return;
    final trimmedName = listName.trim();
    ref.read(shoppingListsProvider.notifier).createNewList(trimmedName);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created and selected list "$trimmedName"')),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String listId, String listName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete "$listName"?'),
          content: const Text('This action is permanent and cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref.read(firestoreServiceProvider).deleteList(listId: listId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    // --- THIS IS THE FIX ---
    // The main container for the bottom sheet. We wrap its content in a Column
    // that uses Expanded to correctly size the TabBarView.
    // The `mainAxisSize.min` on the Column combined with Flexible on the TabBarView
    // is a robust way to handle this.
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Let the content determine the height
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildTabBar(),
            const SizedBox(height: 16),
            // We use Flexible here to allow the TabBarView to take up space,
            // but it will also shrink if the content is small. This is
            // more robust than Expanded for variable content size.
            Flexible(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  // No changes to _buildTabContent needed now, the fix is in the parent.
  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController!,
      children: [
        _buildSelectList(),
        _buildNewListTab(),
      ],
    );
  }

  // ... (THE REST OF THE FILE REMAINS EXACTLY THE SAME) ...

  Widget _buildHeader() {
    final theme = ref.watch(themeProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Manage My Lists',
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
        const Tab(text: 'My Lists'),
        Tab(
          child: Text(
            'Create New',
            style: TextStyle(
              color: isPremium ? null : theme.inactive.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectList() {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
    final activeListId = ref.watch(activeShoppingListProvider);

    if (!isPremium) {
      return ListTile(
        title: Text(merklisteListName, style: TextStyle(color: theme.inactive)),
        onTap: () {
          if (isSelectActiveMode) {
            ref.read(activeShoppingListProvider.notifier).setActiveList(merklisteListName);
            Navigator.pop(context);
          } else {
            _addAndDismiss();
          }
        },
        tileColor: theme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    }

    final allListsAsync = ref.watch(allShoppingListsProvider);

    return allListsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (lists) {
        if (lists.isEmpty) {
          return const Center(child: Text('Your default list is being prepared...'));
        }
        // Use a ListView which is intrinsically scrollable.
        return ListView.builder(
          shrinkWrap: true, // Important inside a Flexible Column
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            final isCurrentlyActive = isSelectActiveMode && list.id == activeListId;
            final isDefaultList = list.name == merklisteListName;

            return Card(
              elevation: isCurrentlyActive ? 2 : 0,
              color: isCurrentlyActive
                  ? theme.secondary.withOpacity(0.9)
                  : theme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.symmetric(vertical: 4), // Add some spacing
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
                    ref.read(shoppingListsProvider.notifier).addToSpecificList(widget.product!, list.id);
                    widget.onConfirm!(list.name);
                  }
                },
                trailing: isDefaultList
                    ? null
                    : IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: isCurrentlyActive ? theme.primary : theme.accent,
                  ),
                  onPressed: () {
                    _showDeleteConfirmationDialog(context, list.id, list.name);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNewListTab() {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;

    if (isPremium) {
      return Column(
        children: [
          TextField(
            controller: _newListController,
            autofocus: _tabController?.index == 1,
            style: TextStyle(color: theme.inactive),
            onSubmitted: _createAndSetActive,
            decoration: InputDecoration(
              labelText: 'Enter new list name',
              labelStyle: TextStyle(color: theme.inactive),
              // ... borders
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.secondary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _createAndSetActive(_newListController.text),
            child: Text(
              'CREATE AND SELECT',
              style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
                context.findAncestorStateOfType<MainAppScreenState>()?.navigateToTab(2);
              },
              child: Text('Upgrade Now', style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }
}