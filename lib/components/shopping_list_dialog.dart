import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/shopping_list_provider.dart';

class ShoppingListDialog extends ConsumerStatefulWidget {
  final Product product;
  final void Function(String selectedListName) onConfirm;

  const ShoppingListDialog({
    super.key,
    required this.product,
    required this.onConfirm,
  });

  @override
  ConsumerState<ShoppingListDialog> createState() => _ShoppingListDialogState();
}

class _ShoppingListDialogState extends ConsumerState<ShoppingListDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _newListController = TextEditingController();
  String? _selectedList;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final shoppingLists = ref.watch(shoppingListsProvider);
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);

    return AlertDialog(
      title: const Text('Add to Shopping List'),
      content: SizedBox(
        height: 300,
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Select List'),
                Tab(text: 'New List'),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Select List Tab
                  shoppingLists.isEmpty
                      ? const Text('No shopping lists. Add a new list.')
                      : SizedBox(
                    height: 200, // Set a fixed height for scrollable list
                    child: ListView.builder(
                      itemCount: shoppingLists.keys.length,
                      itemBuilder: (context, index) {
                        final listName = shoppingLists.keys.elementAt(index);
                        return ListTile(
                          title: Text(listName),
                          selected: _selectedList == listName,
                          selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          onTap: () {
                            setState(() {
                              _newListController.clear();
                              _selectedList = listName;
                            });
                          },
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.deepPurple[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              shoppingListNotifier.addItemToList(listName, widget.product);
                              widget.onConfirm(listName);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added to "$listName"'),
                                  duration: const Duration(seconds: 1),),
                              );
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  // Add List Tab
                  TextField(
                    controller: _newListController,
                    decoration: const InputDecoration(
                      labelText: 'Create new list',
                    ),
                    onChanged: (value) {
                      setState(() => _selectedList = null);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final listName = _newListController.text.isNotEmpty
                ? _newListController.text.trim()
                : _selectedList;

            if (listName != null && listName.isNotEmpty) {
              if (_newListController.text.isNotEmpty && shoppingLists.containsKey(listName)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('List name already exists'),
                    duration: const Duration(seconds: 1),),
                );
                return;
              }
              widget.onConfirm(listName);
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter or select a list name'),
                  duration: const Duration(seconds: 1),),
              );
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _newListController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}