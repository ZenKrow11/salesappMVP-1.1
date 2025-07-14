import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/shopping_list_bottom_sheet.dart';
import '../models/product.dart';
import '../models/named_list.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/theme_color.dart';

// The constant for the special list name should be in your provider file,
// but it's also used here, so we re-declare or import it.
// To avoid duplication, it's best if the provider file exports it.
// For now, we'll define it here to match the provider.
const String merkzettelListName = 'Merkzettel';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingLists = ref.watch(shoppingListsProvider);
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);

    final merkzettel = shoppingLists.firstWhere(
          (list) => list.name == merkzettelListName,
      orElse: () => NamedList(
        name: merkzettelListName,
        items: [],
        index: -1,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.background,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => const ShoppingListBottomSheet(
              initialTabIndex: 1,
            ),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22.0),
            child: Text('Shopping Lists',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                )),
          ),
          _buildListCard(
            context,
            ref,
            merkzettel,
            allowDelete: false,
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final updatedLists = ref.watch(shoppingListsProvider);
              final otherLists = updatedLists
                  .where((list) => list.name != merkzettelListName)
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: AppColors.primary,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
        iconColor: AppColors.secondary,
        collapsedIconColor: AppColors.secondary,
        tilePadding:
        const EdgeInsets.only(left: 20, right: 16, top: 8, bottom: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (list.name == merkzettelListName) ...[
                    const Icon(Icons.note_alt_outlined, color: AppColors.secondary, size: 24),
                    const SizedBox(width: 12),
                  ],
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
                ],
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
}

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