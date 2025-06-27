import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/named_list.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/theme_color.dart';

const String favoritesListName = 'Favorites';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingLists = ref.watch(shoppingListsProvider);
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);

    // Separate favorites from other lists
    final favorites = shoppingLists.firstWhere(
          (list) => list.name == favoritesListName,
      orElse: () => NamedList(
        name: favoritesListName,
        items: [],
        index: -1,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Compute otherLists here for _showAddListDialog to ensure it's up-to-date
          final otherLists = shoppingLists
              .where((list) => list.name != favoritesListName)
              .toList()
            ..sort((a, b) => a.index.compareTo(b.index));
          _showAddListDialog(context, shoppingListNotifier, otherLists);
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add,
          size: 32,
          color: AppColors.primary,),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          // --- Favorites First (Static) ---
          _buildListCard(
            context,
            ref,
            favorites,
            allowDelete: false,
          ),

          const SizedBox(height: 12),

          // --- Draggable Custom Lists ---
          Consumer(
            builder: (context, ref, child) {
              final updatedLists = ref.watch(shoppingListsProvider);
              final otherLists = updatedLists
                  .where((list) => list.name != favoritesListName)
                  .toList()
                ..sort((a, b) => a.index.compareTo(b.index));

              return ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex < newIndex) newIndex -= 1;
                  final reordered = [...otherLists];
                  final item = reordered.removeAt(oldIndex);
                  reordered.insert(newIndex, item);
                  shoppingListNotifier.reorderCustomLists(reordered);
                },
                children: otherLists.map((list) {
                  return _buildListCard(
                    context,
                    ref,
                    list,
                    allowDelete: true,
                    key: ValueKey(list.name),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(
      BuildContext context,
      WidgetRef ref,
      NamedList list, {
        required bool allowDelete,
        Key? key,
      }) {
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);

    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ExpansionTile(
        backgroundColor: AppColors.inactive,
        collapsedBackgroundColor: AppColors.primary,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          list.name,
          style: const TextStyle(
              color: AppColors.active,
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: allowDelete
            ? IconButton(
          icon: const Icon(Icons.delete, color: Colors.red, size: 30),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete List'),
                content: Text('Are you sure you want to delete "${list.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      shoppingListNotifier.deleteList(list.name);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${list.name}"'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        )
            : const SizedBox(width: 30),
        children: list.items.isEmpty
            ? [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('This list is empty.'),
          ),
        ]
            : list.items.asMap().entries.map((entry) {
          final product = entry.value;
          return ShoppingListItemTile(
            product: product,
            listName: list.name,
            onRemove: () {
              shoppingListNotifier.removeItemFromList(list.name, product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed from "${list.name}"'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  void _showAddListDialog(BuildContext context, ShoppingListNotifier notifier, List<NamedList> currentLists) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New List'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'List name',
            hintText: 'Enter list name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final listName = controller.text.trim();

              if (listName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('List name cannot be empty'),
                    duration: Duration(seconds: 1),
                  ),
                );
                return;
              }

              if (currentLists.any((list) => list.name == listName) || listName == favoritesListName) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('List name already exists'),
                    duration: Duration(seconds: 1),
                  ),
                );
                return;
              }

              notifier.addEmptyList(listName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Created "$listName"'),
                  duration: const Duration(seconds: 1),
                ),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// Placeholder for ShoppingListItemTile (replace with your actual implementation)
class ShoppingListItemTile extends StatelessWidget {
  final Product product;
  final String listName;
  final VoidCallback onRemove;

  const ShoppingListItemTile({
    Key? key,
    required this.product,
    required this.listName,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(product.name),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle, color: Colors.red),
        onPressed: onRemove,
      ),
    );
  }
}