// lib/pages/shopping_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main_app_screen.dart';
import '../components/shopping_list_bottom_sheet.dart';
import '../models/product.dart';

import '../models/named_list.dart';
import '../pages/product_swiper_screen.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/image_aspect_ratio.dart';

import '../widgets/slide_up_page_route.dart';
import '../providers/user_profile_provider.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final shoppingLists = ref.watch(shoppingListsProvider);
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;

    final merkliste = shoppingLists.firstWhere(
          (list) => list.name == merklisteListName,
      orElse: () => NamedList(name: merklisteListName, items: [], index: -1),
    );

    return Scaffold(
      backgroundColor: theme.primary,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isPremium) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const ShoppingListBottomSheet(initialTabIndex: 1),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('This is a Premium Feature!'),
                action: SnackBarAction(
                  label: 'UPGRADE',
                  onPressed: () {
                    // --- THIS LOGIC IS NOW CORRECT ---
                    final mainAppScreenState = context.findAncestorStateOfType<MainAppScreenState>();
                    if (mainAppScreenState != null) {
                      mainAppScreenState.navigateToTab(2); // Navigate to the Account Page
                    }
                  },
                ),
              ),
            );
          }
        },
        backgroundColor: isPremium ? theme.secondary : theme.inactive.withOpacity(0.5),
        child: Icon(Icons.add, size: 32, color: isPremium ? theme.primary : theme.primary.withOpacity(0.7)),
      ),
      body: SafeArea(
        child: Container(
          color: theme.pageBackground,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
                child: Text(
                  'Saved Lists',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.secondary),
                ),
              ),
              const SizedBox(height: 4),
              _buildListCard(context, ref, merkliste, theme: theme, allowDelete: false),
              const SizedBox(height: 16),
              if (isPremium)
                Consumer(
                  builder: (context, ref, child) {
                    final updatedLists = ref.watch(shoppingListsProvider);
                    final otherLists = updatedLists
                        .where((list) => list.name != merklisteListName)
                        .toList()
                      ..sort((a, b) => a.index.compareTo(b.index));

                    if (otherLists.isEmpty) {
                      return const SizedBox.shrink();
                    }

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
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, WidgetRef ref, NamedList list, {required AppThemeData theme, required bool allowDelete, Key? key}) {
    final shoppingListNotifier = ref.read(shoppingListsProvider.notifier);
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: theme.background,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        backgroundColor: theme.background,
        iconColor: theme.secondary,
        collapsedIconColor: theme.secondary,
        tilePadding: const EdgeInsets.only(left: 20, right: 16, top: 8, bottom: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        leading: Icon(
          list.name == merklisteListName ? Icons.note_alt_outlined : Icons.list_alt_rounded,
          color: theme.secondary,
          size: 28,
        ),
        title: Text(
          list.name,
          style: TextStyle(color: theme.secondary, fontSize: 18, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: allowDelete ? IconButton(
          icon: Icon(Icons.delete_outline, color: theme.accent, size: 28),
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
            ? [Padding(padding: const EdgeInsets.fromLTRB(20, 8, 16, 8), child: Text('This list is empty.', style: TextStyle(color: theme.inactive.withOpacity(0.7))))]
            : list.items.map((product) {
          return ShoppingListItemTile(
            product: product,
            allProductsInList: list.items,
            listName: list.name,
            theme: theme,
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

class ShoppingListItemTile extends StatelessWidget {
  final Product product;
  final List<Product> allProductsInList;
  final String listName;
  final AppThemeData theme;
  final VoidCallback onRemove;

  const ShoppingListItemTile({
    super.key,
    required this.product,
    required this.allProductsInList,
    required this.listName,
    required this.theme,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final priceString = product.currentPrice.toStringAsFixed(2);
    final discount = product.discountPercentage ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        final initialIndex = allProductsInList.indexWhere((p) => p.id == product.id);
        if (initialIndex != -1) {
          Navigator.of(context).push(SlideUpPageRoute(
            page: ProductSwiperScreen(
              products: allProductsInList,
              initialIndex: initialIndex,
            ),
          ));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: ImageWithAspectRatio(
                imageUrl: product.imageUrl ?? '',
                maxWidth: 70,
                maxHeight: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.store,
                    style: TextStyle(color: theme.inactive.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$priceString Fr.',
                  style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                if (discount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$discount%',
                      style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.close, color: theme.accent, size: 24),
              onPressed: onRemove,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.only(left: 12, right: 4),
            ),
          ],
        ),
      ),
    );
  }
}