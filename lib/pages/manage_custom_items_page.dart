// lib/pages/manage_custom_items_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sales_app_mvp/pages/manage_shopping_list.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/create_custom_item_page.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/slide_in_page_route.dart';
import 'package:sales_app_mvp/services/notification_manager.dart';

class ManageCustomItemsPage extends ConsumerWidget {
  const ManageCustomItemsPage({super.key});

  Future<void> _showDeleteConfirmation(
      BuildContext context,
      WidgetRef ref,
      Product item,
      ) async {
    // Unchanged
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.background,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            l10n.deleteItemConfirmationTitle(item.name),
            style:
            TextStyle(color: theme.secondary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            l10n.deleteItemConfirmationBody,
            style: TextStyle(color: theme.inactive),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.inactive,
                side: BorderSide(color: theme.inactive.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await ref
                    .read(firestoreServiceProvider)
                    .deleteCustomItemFromStorage(item.id);
                ref.invalidate(customItemsProvider);
                Navigator.pop(context);
                NotificationManager.show(context, l10n.itemDeleted(item.name));
              },
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }

  // --- MODIFIED: Replaced _showAddToListSheet with a navigation method ---
  void _navigateToAddToListPage(
      BuildContext context, WidgetRef ref, Product product) async {
    final l10n = AppLocalizations.of(context)!;

    // Use Navigator.push with SlidePageRoute and await the string result.
    final selectedListName = await Navigator.of(context, rootNavigator: true)
        .push<String>(
      SlidePageRoute(
        page: ManageShoppingListsPage(product: product),
        direction: SlideDirection.rightToLeft,
      ),
    );

    // After the ManageShoppingListsPage is popped, check if it returned a list name.
    // The context.mounted check is a good safety measure after an async operation.
    if (selectedListName != null && context.mounted) {
      NotificationManager.show(
          context, l10n.itemAddedToList(product.name, selectedListName));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Unchanged until the ListTile onTap
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
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: theme.secondary, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.manageCustomItemsTitle,
          style: TextStyle(
              color: theme.secondary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  l10n.customItemsEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: theme.inactive.withOpacity(0.7), fontSize: 16),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                color: theme.primary,
                margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(
                        color: theme.inactive, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    item.category == 'custom' && item.subcategory.isNotEmpty
                        ? item.subcategory
                        : l10n.customItem,
                    style: TextStyle(color: theme.inactive.withOpacity(0.7)),
                  ),
                  // --- THIS IS THE KEY CHANGE ---
                  onTap: () => _navigateToAddToListPage(context, ref, item),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: theme.inactive),
                    tooltip: l10n.moreOptions,
                    color: theme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.of(context, rootNavigator: true).push(
                          SlidePageRoute(
                            page: CreateCustomItemPage(productToEdit: item),
                            direction: SlideDirection.rightToLeft,
                          ),
                        );
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, ref, item);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading:
                          Icon(Icons.edit_outlined, color: theme.inactive),
                          title: Text(l10n.editCustomItem,
                              style: TextStyle(color: theme.inactive)),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading:
                          Icon(Icons.delete_outline, color: theme.accent),
                          title: Text(l10n.delete,
                              style: TextStyle(color: theme.accent)),
                        ),
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
          final countText = '${l10n.itemsLabel} ${items.length} / $limit';
          final isLimitReached = items.length >= limit;

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: theme.primary,
                border: Border(
                    top: BorderSide(color: theme.background, width: 1.0)),
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
                    onPressed: isLimitReached
                        ? null
                        : () => Navigator.of(context, rootNavigator: true)
                        .push(SlidePageRoute(
                      page: const CreateCustomItemPage(),
                      direction: SlideDirection.rightToLeft,
                    )),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.add),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLimitReached
                          ? theme.inactive.withOpacity(0.4)
                          : theme.secondary,
                      foregroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}