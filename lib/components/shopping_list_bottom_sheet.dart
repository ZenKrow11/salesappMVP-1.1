import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/theme_color.dart'; // Assuming theme_color.dart exists

const String favoritesListName = 'Favorites';

class ShoppingListBottomSheet extends ConsumerStatefulWidget {
  final Product product;
  final void Function(String selectedListName) onConfirm;

  const ShoppingListBottomSheet({
    super.key,
    required this.product,
    required this.onConfirm,
  });

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final shoppingLists = ref.watch(shoppingListsProvider);
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add to Shopping List',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.accent,),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const Divider(thickness: 1, height: 24),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.secondary,
            unselectedLabelColor: AppColors.inactive,
            indicatorColor: AppColors.secondary,
            tabs: const [
              Tab(text: 'Select List'),
              Tab(text: 'New List'),
            ],
          ),
          const SizedBox(height: 16),

          // Tab Content
          SizedBox(
            // Constrain height to make content scrollable
            height: 220,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Select List Tab
                shoppingLists.isEmpty
                    ? const Center(
                  child: Text(
                    'No shopping lists yet.\nCreate one in the "New List" tab.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inactive),
                  ),
                )
                    : ListView.builder(
                  itemCount: shoppingLists.length,
                  itemBuilder: (context, index) {
                    final list = shoppingLists[index];
                    final listName = list.name;
                    return ListTile(
                      title: Text(listName, style: const TextStyle(color: AppColors.primary)),
                      selected: _selectedList == listName,
                      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                      onTap: () {
                        setState(() {
                          _newListController.clear();
                          _selectedList = listName;
                        });
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.add, color: AppColors.primary),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.secondary.withValues(alpha: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          shoppingListNotifier.addToList(listName, widget.product);
                          widget.onConfirm(listName);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to "$listName"'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),

                // Add List Tab
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: _newListController,
                    style: const TextStyle(color: AppColors.primary),
                    decoration: InputDecoration(
                      labelText: 'Create new list name',
                      labelStyle: const TextStyle(color: AppColors.inactive),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.inactive.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(8.0)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.secondary),
                          borderRadius: BorderRadius.circular(8.0)),
                    ),
                    onChanged: (value) {
                      setState(() => _selectedList = null);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: AppColors.inactive, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final listName = _newListController.text.isNotEmpty
                        ? _newListController.text.trim()
                        : _selectedList;

                    if (listName != null && listName.isNotEmpty) {
                      if (_newListController.text.isNotEmpty && shoppingLists.any((list) => list.name == listName)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('List name already exists'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        return;
                      }
                      if (_newListController.text.isNotEmpty) {
                        // Create new list and add item
                        shoppingListNotifier.addEmptyList(listName);
                      }
                      // Add to selected or newly created list
                      shoppingListNotifier.addToList(listName, widget.product);
                      widget.onConfirm(listName);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to "$listName"'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter or select a list name'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: const Text('CONFIRM', style: TextStyle(color: AppColors.inactive,
                  fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newListController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}