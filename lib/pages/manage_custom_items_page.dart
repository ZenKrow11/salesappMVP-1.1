import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:uuid/uuid.dart';

class ManageCustomItemsPage extends ConsumerWidget {
  const ManageCustomItemsPage({super.key});

  Future<void> _showCreateOrEditDialog(
      BuildContext context,
      WidgetRef ref, {
        Product? productToEdit,
      }) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = ref.read(themeProvider);
    final userProfile = ref.read(userProfileProvider).value;
    final customItems = ref.read(customItemsProvider).value ?? [];

    final isEditing = productToEdit != null;
    final nameController = TextEditingController(text: productToEdit?.name ?? '');
    final limit = userProfile?.isPremium == true ? 45 : 15;

    // Enforce limit only when creating new items
    if (!isEditing && customItems.length >= limit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.customItemLimitReached(limit)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            isEditing ? l10n.editCustomItem : l10n.createCustomItem,
            style: TextStyle(color: theme.secondary),
          ),
          content: TextField(
            controller: nameController,
            style: TextStyle(color: theme.inactive),
            decoration: InputDecoration(
              labelText: l10n.itemName,
              labelStyle: TextStyle(color: theme.inactive.withOpacity(0.7)),
              filled: true,
              fillColor: theme.background.withOpacity(0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.secondary, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel, style: TextStyle(color: theme.inactive)),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.secondary,
                foregroundColor: theme.primary,
              ),
              icon: const Icon(Icons.check),
              label: Text(isEditing ? l10n.saveChanges : l10n.createItem),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final firestore = ref.read(firestoreServiceProvider);

                final newProduct = Product(
                  id: isEditing ? productToEdit.id : const Uuid().v4(),
                  name: name,
                  store: 'custom',
                  category: 'custom',
                  subcategory: '',
                  currentPrice: 0.0,
                  normalPrice: 0.0,
                  discountPercentage: 0,
                  url: '',
                  imageUrl: '',
                  nameTokens: [],
                  isCustom: true,
                );

                if (isEditing) {
                  await firestore.updateCustomItemInStorage(newProduct);
                } else {
                  await firestore.addCustomItemToStorage(newProduct);
                }

                ref.invalidate(customItemsProvider);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? l10n.itemSavedSuccessfully(name)
                          : l10n.itemAddedToList(name),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context,
      WidgetRef ref,
      Product item,
      ) async {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            l10n.deleteItemConfirmationTitle(item.name),
            style: TextStyle(color: theme.secondary),
          ),
          content: Text(
            l10n.deleteItemConfirmationBody,
            style: TextStyle(color: theme.inactive),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel, style: TextStyle(color: theme.inactive)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.secondary,
                foregroundColor: theme.primary,
              ),
              onPressed: () async {
                await ref.read(firestoreServiceProvider).deleteCustomItemFromStorage(item.id);
                ref.invalidate(customItemsProvider);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.itemDeleted(item.name)),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }

  void _addToShoppingList(BuildContext context, WidgetRef ref, Product product) {
    final l10n = AppLocalizations.of(context)!;
    final activeListId = ref.read(activeShoppingListProvider);
    ref.read(shoppingListsProvider.notifier).addToSpecificList(product, activeListId, context);

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.itemAddedToList(product.name)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    final customItemsAsync = ref.watch(customItemsProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final limit = userProfile?.isPremium == true ? 45 : 15;

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        elevation: 0,
        automaticallyImplyLeading: false, // ✅ removes back arrow
        title: Text(
          l10n.manageCustomItemsTitle,
          style: TextStyle(color: theme.secondary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: theme.accent), // ✅ close X stays
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: customItemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            l10n.error(err.toString()),
            style: TextStyle(color: theme.inactive),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                l10n.customItemsEmpty,
                style: TextStyle(color: theme.inactive.withOpacity(0.7), fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                color: theme.background,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(color: theme.secondary, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    item.category == 'custom'
                        ? l10n.customCategoryPremium
                        : item.category,
                    style: TextStyle(color: theme.inactive.withOpacity(0.7)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart_outlined),
                        color: theme.secondary,
                        tooltip: l10n.addToList,
                        onPressed: () => _addToShoppingList(context, ref, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        color: theme.secondary,
                        tooltip: l10n.editCustomItem,
                        onPressed: () =>
                            _showCreateOrEditDialog(context, ref, productToEdit: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: theme.accent,
                        tooltip: l10n.delete,
                        onPressed: () =>
                            _showDeleteConfirmation(context, ref, item),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: customItemsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (items) {
          final countText = 'Items ${items.length} / $limit';
          final isLimitReached = items.length >= limit;

          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: theme.primary,
              border: Border(top: BorderSide(color: theme.background, width: 1.0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  countText,
                  style: TextStyle(
                    color: theme.inactive.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                  isLimitReached ? null : () => _showCreateOrEditDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.add),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLimitReached
                        ? theme.inactive.withOpacity(0.4)
                        : theme.secondary,
                    foregroundColor: theme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
