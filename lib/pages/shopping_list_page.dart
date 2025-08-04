import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/shopping_list_bottom_sheet.dart';
import '../models/product.dart';
import '../models/named_list.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/app_theme.dart'; // CORRECTED: Import the theme provider file

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Correctly watch the theme provider to get theme data
    final theme = ref.watch(themeProvider);
    final shoppingLists = ref.watch(shoppingListsProvider);
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);

    final merkliste = shoppingLists.firstWhere(
          (list) => list.name == merklisteListName,
      orElse: () => NamedList(name: merklisteListName, items: [], index: -1),
    );

    return Scaffold(
      // Use the theme object for colors
      backgroundColor: theme.primary,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: theme.background,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => const ShoppingListBottomSheet(initialTabIndex: 1),
          );
        },
        backgroundColor: theme.secondary,
        child: Icon(Icons.add, size: 32, color: theme.primary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
            child: Text(
              'Saved Lists',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.secondary),
            ),
          ),
          // Pass the theme object down to the helper method
          _buildListCard(context, ref, merkliste, theme: theme, allowDelete: false),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final updatedLists = ref.watch(shoppingListsProvider);
              final otherLists = updatedLists
                  .where((list) => list.name != merklisteListName)
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
                  return _buildListCard(context, ref, list, theme: theme, allowDelete: true, key: ValueKey(list.name));
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper method now accepts the theme data
  Widget _buildListCard(BuildContext context, WidgetRef ref, NamedList list, {required AppThemeData theme, required bool allowDelete, Key? key}) {
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: theme.pageBackground,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        backgroundColor: theme.pageBackground,
        iconColor: theme.inactive,
        collapsedIconColor: theme.secondary,
        tilePadding: const EdgeInsets.only(left: 20, right: 16, top: 8, bottom: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        title: Row(
          children: [
            if (list.name == merklisteListName) ...[
              Icon(Icons.note_alt_outlined, color: theme.inactive, size: 24),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                list.name,
                style: TextStyle(color: theme.inactive, fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: allowDelete ? IconButton(
          icon: Icon(Icons.delete, color: theme.accent, size: 28),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete List'),
                content: Text('Are you sure you want to delete "${list.name}"?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      shoppingListNotifier.deleteList(list.name);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted "${list.name}"'), duration: const Duration(seconds: 1)));
                      Navigator.of(context).pop();
                    },
                    child: Text('Delete', style: TextStyle(color: theme.accent)),
                  ),
                ],
              ),
            );
          },
        ) : null,
        children: list.items.isEmpty
            ? [Padding(padding: const EdgeInsets.all(16.0), child: Text('This list is empty.', style: TextStyle(color: Colors.grey.shade600)))]
            : list.items.map((product) {
          return ShoppingListItemTile(
            product: product,
            listName: list.name,
            theme: theme, // Pass theme down to the item tile
            onRemove: () {
              shoppingListNotifier.removeItemFromList(list.name, product);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed from "${list.name}"'), duration: const Duration(seconds: 1)));
            },
          );
        }).toList(),
      ),
    );
  }
}

/// The item tile widget, now receiving the theme data via its constructor.
class ShoppingListItemTile extends StatelessWidget {
  final Product product;
  final String listName;
  final AppThemeData theme; // Field to hold the theme data
  final VoidCallback onRemove;

  const ShoppingListItemTile({
    super.key,
    required this.product,
    required this.listName,
    required this.theme, // Make theme a required parameter
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final priceString = product.currentPrice.toStringAsFixed(2) ?? 'N/A';
    final discount = product.discountPercentage ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Image.network(
                product.imageUrl ?? '',
                width: 100,
                height: 56.25,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 56.25,
                  color: theme.background, // Use theme object
                  child: Icon(Icons.broken_image, color: theme.inactive.withOpacity(0.5)),
                ),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(width: 100, height: 56.25, color: theme.background),
              ),
            ),
            const SizedBox(width: 12),
            // Middle: Title & Store Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.store,
                    style: TextStyle(color: theme.inactive.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right: Price & Discount Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  '$priceString Fr.',
                  style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (discount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.primary, // Use theme object
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$discount%',
                      style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],
            ),
            // Far Right: Remove Button
            IconButton(
              icon: Icon(Icons.close, color: theme.accent, size: 24), // Use theme object
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}