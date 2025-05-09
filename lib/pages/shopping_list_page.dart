import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shopping_list_provider.dart';
import '../models/product.dart';

class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  @override
  Widget build(BuildContext context) {
    final shoppingLists = ref.watch(shoppingListsProvider);
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddListDialog(context, shoppingListNotifier),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: shoppingLists.isEmpty
          ? const Center(child: Text('No shopping lists yet.'))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: shoppingLists.keys.length,
        itemBuilder: (context, index) {
          final listName = shoppingLists.keys.elementAt(index);
          final items = shoppingLists[listName]!;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: ExpansionTile(
              title: Text(
                listName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 30,
                ),
                onPressed: () {
                  // Confirm deletion
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete List'),
                      content: Text('Are you sure you want to delete "$listName"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            shoppingListNotifier.deleteList(listName);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Deleted "$listName"'),
                                duration: const Duration(seconds: 1),),
                            );
                            Navigator.of(context).pop();
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              children: items.isEmpty
                  ? [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('This list is empty.'),
                ),
              ]
                  : items.asMap().entries.map((entry) {
                final product = entry.value;
                return ShoppingListItemTile(
                  product: product,
                  listName: listName,
                  onRemove: () {
                    shoppingListNotifier.removeItemFromList(listName, product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Removed from "$listName"'),
                        duration: const Duration(seconds: 1),),
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  void _showAddListDialog(BuildContext context, ShoppingListNotifier notifier) {
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
                  const SnackBar(content: Text('List name cannot be empty'),
                    duration: const Duration(seconds: 1),),
                );
                return;
              }
              if (notifier.getListNames().contains(listName)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('List name already exists'),
                    duration: const Duration(seconds: 1),),
                );
                return;
              }
              notifier.addEmptyList(listName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Created "$listName"'),
                  duration: const Duration(seconds: 1),),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Leading: Item image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // Middle: Store, name, discount, price
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column 1: Store and name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.store,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Column 2: Discount and price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-${product.discountPercentage}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${product.currentPrice.toStringAsFixed(2)}.-',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Trailing: Delete button
            IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete,
                size: 30,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}