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
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/services/notification_manager.dart';


class ManageCustomItemsPage extends ConsumerWidget {
  const ManageCustomItemsPage({super.key});

  // The old _showCreateItemDialog method has been completely removed.

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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                backgroundColor: theme.accent,
                foregroundColor: Colors.white,
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

  void _showMoreActions(BuildContext context, WidgetRef ref, Product item) {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.edit_outlined, color: theme.inactive),
                title: Text(l10n.editCustomItem,
                    style: TextStyle(color: theme.inactive)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context, rootNavigator: true).push(
                    SlideUpPageRoute(
                        page: CreateCustomItemPage(productToEdit: item)),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.accent),
                title: Text(l10n.delete, style: TextStyle(color: theme.accent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(context, ref, item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToListSheet(
      BuildContext context, WidgetRef ref, Product product) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ManageShoppingListsPage(
        product: product,
        onConfirm: (selectedListName) {
          NotificationManager.show(context, l10n.itemAddedToList(selectedListName));
          Navigator.pop(ctx);
        },
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
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: theme.secondary, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.manageCustomItemsTitle,
          style: TextStyle(color: theme.secondary),
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
                color: theme.background,
                margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    item.name,
                    style: TextStyle(
                        color: theme.secondary, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    item.category == 'custom' && item.subcategory.isNotEmpty
                        ? item.subcategory
                        : l10n.customItem,
                    style: TextStyle(color: theme.inactive.withOpacity(0.7)),
                  ),
                  onTap: () => _showAddToListSheet(context, ref, item),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    color: theme.inactive,
                    tooltip: l10n.moreOptions,
                    onPressed: () => _showMoreActions(context, ref, item),
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
                border:
                Border(top: BorderSide(color: theme.background, width: 1.0)),
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
                    // --- FIX: THIS NOW NAVIGATES DIRECTLY TO THE FULL PAGE ---
                    onPressed: isLimitReached
                        ? null
                        : () => Navigator.of(context, rootNavigator: true)
                        .push(SlideUpPageRoute(
                        page: const CreateCustomItemPage())),
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