// lib/pages/manage_shopping_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/components/upgrade_dialog.dart';

class ManageShoppingListsPage extends ConsumerStatefulWidget {
  final Product? product;
  final void Function(String selectedListName)? onConfirm;

  const ManageShoppingListsPage({
    super.key,
    this.product,
    this.onConfirm,
  }) : assert(product == null || onConfirm != null,
  'onConfirm must be provided when a product is given');

  @override
  ConsumerState<ManageShoppingListsPage> createState() =>
      _ManageShoppingListsPageState();
}

class _ManageShoppingListsPageState extends ConsumerState<ManageShoppingListsPage> {
  final TextEditingController _newListController = TextEditingController();

  bool get isSelectActiveMode => widget.product == null;

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  void _addAndDismiss() {
    final l10n = AppLocalizations.of(context)!;
    if (widget.product == null) return;
    ref.read(shoppingListsProvider.notifier).addToList(widget.product!, context);
    widget.onConfirm!(kDefaultListName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.addedTo(kDefaultListName))),
    );
    Navigator.of(context).pop();
  }

  void _createAndSetActive(String listName) {
    final l10n = AppLocalizations.of(context)!;
    if (listName.trim().isEmpty) return;

    final trimmedName = listName.trim();
    ref.read(shoppingListsProvider.notifier).createNewList(trimmedName);
    ref.read(activeShoppingListProvider.notifier).setActiveList(trimmedName);

    if(Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.createdAndSelectedList(trimmedName))),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String listId, String listName) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteListConfirmationTitle(listName)),
          content: Text(l10n.deleteListConfirmationBody),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.delete),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref
                    .read(firestoreServiceProvider)
                    .deleteList(listId: listId);
              },
            ),
          ],
        );
      },
    );
  }

  void _showCreateListDialog() {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    _newListController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(l10n.createNew, style: TextStyle(color: theme.secondary)),
          content: TextField(
            controller: _newListController,
            autofocus: true,
            style: TextStyle(color: theme.inactive),
            onSubmitted: _createAndSetActive,
            decoration: InputDecoration(
              labelText: l10n.enterNewListName,
              labelStyle: TextStyle(color: theme.inactive),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.secondary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel, style: TextStyle(color: theme.inactive)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: theme.secondary),
              onPressed: () => _createAndSetActive(_newListController.text),
              child: Text(l10n.createAndSelect, style: TextStyle(color: theme.primary)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    final allListsAsync = ref.watch(allShoppingListsProvider);

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
          l10n.manageMyLists,
          style: TextStyle(color: theme.secondary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: allListsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.error(err.toString()))),
        data: (lists) {
          final customLists = lists.where((list) => list.name != kDefaultListName).toList();
          if (customLists.isEmpty && lists.length <= 1) {
            return _buildEmptyState(l10n, theme);
          }
          return _buildSelectList(l10n, lists);
        },
      ),
      bottomNavigationBar: allListsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (lists) {
            final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
            const int maxPremiumLists = 9;
            final bool canCreateMore = isPremium && lists.length < maxPremiumLists;

            return SafeArea(
              child: Container(
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
                      '${l10n.listsLabel} ${lists.length} / ${isPremium ? maxPremiumLists : 1}',
                      style: TextStyle(
                        color: theme.inactive.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: !isPremium
                          ? () => showUpgradeDialog(context, ref)
                          : (canCreateMore ? _showCreateListDialog : null),
                      icon: Icon(isPremium ? Icons.add : Icons.lock),
                      label: Text(l10n.createNew),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isPremium && canCreateMore)
                            ? theme.secondary
                            : theme.inactive.withOpacity(0.4),
                        foregroundColor: theme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, AppThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          l10n.shoppingListsEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: theme.inactive.withOpacity(0.7), fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSelectList(AppLocalizations l10n, List<ShoppingListInfo> lists) {
    final theme = ref.watch(themeProvider);
    final activeListId = ref.watch(activeShoppingListProvider);

    ShoppingListInfo? defaultList;
    List<ShoppingListInfo> customLists = [];
    for (var list in lists) {
      if (list.name == kDefaultListName) {
        defaultList = list;
      } else {
        customLists.add(list);
      }
    }
    customLists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final orderedLists = <ShoppingListInfo>[];
    if (defaultList != null) {
      orderedLists.add(defaultList);
    }
    orderedLists.addAll(customLists);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      itemCount: orderedLists.length,
      itemBuilder: (context, index) {
        final list = orderedLists[index];
        final isCurrentlyActive = isSelectActiveMode && list.id == activeListId;
        final isDefaultList = list.name == merklisteListName;

        return ListTile(
          leading: isCurrentlyActive
              ? Icon(Icons.check, color: theme.secondary)
              : const SizedBox(width: 24),
          title: Text(
            list.name,
            style: TextStyle(
              fontWeight: isCurrentlyActive ? FontWeight.bold : FontWeight.normal,
              color: isCurrentlyActive ? theme.secondary : theme.inactive,
            ),
          ),
          onTap: () {
            if (isSelectActiveMode) {
              ref.read(activeShoppingListProvider.notifier).setActiveList(list.id);
              Navigator.pop(context);
            } else {
              ref.read(shoppingListsProvider.notifier).addToSpecificList(widget.product!, list.id, context);
              widget.onConfirm!(list.name);
            }
          },
          trailing: isDefaultList
              ? null
              : IconButton(
            icon: Icon(Icons.delete_outline, color: theme.accent),
            onPressed: () => _showDeleteConfirmationDialog(context, list.id, list.name),
          ),
        );
      },
    );
  }
}