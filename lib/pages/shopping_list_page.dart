import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/create_list_bottom_sheet.dart';
import '../models/product.dart';
import '../models/named_list.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/theme_color.dart';

const String favoritesListName = 'Favorites';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingLists = ref.watch(shoppingListsProvider);
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);

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
          // --- FIX: Call the new, reusable bottom sheet ---
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent, // Let the child handle color
            builder: (ctx) => const CreateListBottomSheet(),
          );
        },
        backgroundColor: AppColors.secondary,
        child: const Icon(
          Icons.add,
          size: 32,
          color: AppColors.primary,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // --- Page Header (Inspired by ActiveListSelector) ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22.0),
            child: Text('Shopping Lists',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                )),
          ),

          // --- Favorites First (Static) ---
          _buildListCard(
            context,
            ref,
            favorites,
            allowDelete: false,
          ),
          const SizedBox(height: 16), // Adjusted for margin

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

    // Card wrapper provides the container and elevation
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: AppColors.primary,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        // --- FIX: Add these two lines to remove the default borders ---
        shape: const Border(),
        collapsedShape: const Border(),
        // --- End of Fix ---
        backgroundColor: AppColors.secondary.withValues(alpha: 0.1), // Corrected .withValues to .withOpacity
        iconColor: AppColors.secondary,
        collapsedIconColor: AppColors.secondary,
        tilePadding: const EdgeInsets.only(left: 20, right: 16, top: 8, bottom: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                list.name,
                style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (allowDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.accent, size: 28),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete List'),
                      content: Text(
                          'Are you sure you want to delete "${list.name}"?'),
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
                          child: const Text('Delete',
                              style: TextStyle(color: AppColors.accent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        // By removing the `trailing` property, the default expand/collapse arrow is used
        children: list.items.isEmpty
            ? [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('This list is empty.',
                style: TextStyle(color: AppColors.inactive)),
          ),
        ]
            : list.items.asMap().entries.map((entry) {
          final product = entry.value;
          return ShoppingListItemTile(
            product: product,
            listName: list.name,
            onRemove: () {
              shoppingListNotifier.removeItemFromList(
                  list.name, product);
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
}

// Placeholder for ShoppingListItemTile
class ShoppingListItemTile extends StatelessWidget {
  final Product product;
  final String listName;
  final VoidCallback onRemove;

  const ShoppingListItemTile({
    super.key,
    required this.product,
    required this.listName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title:
      Text(product.name, style: const TextStyle(color: AppColors.active)),
      subtitle:
      Text(product.store, style: TextStyle(color: AppColors.inactive)),
      trailing: IconButton(
        icon: const Icon(Icons.close, color: AppColors.accent, size: 24),
        onPressed: onRemove,
      ),
    );
  }
}