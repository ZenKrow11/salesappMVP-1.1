// lib/pages/manage_shopping_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
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

class _ManageShoppingListsPageState
    extends ConsumerState<ManageShoppingListsPage> {
  final TextEditingController _listNameController = TextEditingController();

  bool get isSelectActiveMode => widget.product == null;

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  // ... (All methods like _createNewList, _showCreateListSheet, etc. are unchanged)
  void _createNewList(String listName) {
    if (listName.trim().isEmpty) return;
    final trimmedName = listName.trim();
    ref
        .read(shoppingListsProvider.notifier)
        .createNewList(trimmedName)
        .catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    });
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _renameList(String listId, String newName) {
    if (newName.trim().isEmpty) return;
    final trimmedName = newName.trim();
    ref.read(shoppingListsProvider.notifier).renameList(listId, trimmedName);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String listId, String listName) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ref.read(themeProvider);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.background,
          title: Text(l10n.deleteListConfirmationTitle(listName), style: TextStyle(color: theme.secondary)),
          content: Text(l10n.deleteListConfirmationBody, style: TextStyle(color: theme.inactive)),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel, style: TextStyle(color: theme.inactive)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: theme.accent),
              child: Text(l10n.delete),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref.read(shoppingListsProvider.notifier).deleteList(listId);
              },
            ),
          ],
        );
      },
    );
  }

  void _showCreateListSheet() {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    _listNameController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // --- THIS IS THE FIX ---
        // Wrap the content in a SafeArea to respect the system navigation bar.
        return SafeArea(
          child: Padding(
            // The bottom padding now correctly combines the keyboard inset AND the safe area.
            padding: EdgeInsets.fromLTRB(20, 20, 20,
                MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.createNew, style: TextStyle(color: theme.secondary, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: _listNameController,
                  autofocus: true,
                  style: TextStyle(color: theme.inactive),
                  onSubmitted: _createNewList,
                  decoration: InputDecoration(
                    labelText: l10n.enterNewListName,
                    labelStyle: TextStyle(color: theme.inactive.withOpacity(0.7)),
                    filled: true,
                    fillColor: theme.primary,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: theme.secondary,
                      minimumSize: const Size(double.infinity, 50)),
                  onPressed: () => _createNewList(_listNameController.text),
                  child: Text(l10n.create, style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditListDialog(ShoppingListInfo list) {
    final theme = ref.read(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    _listNameController.text = list.name;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(l10n.renameListTitle, style: TextStyle(color: theme.secondary)),
          content: TextField(
            controller: _listNameController,
            autofocus: true,
            style: TextStyle(color: theme.inactive),
            onSubmitted: (value) => _renameList(list.id, value),
            decoration: InputDecoration(
              labelText: l10n.listNameLabel,
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
              onPressed: () => _renameList(list.id, _listNameController.text),
              child: Text(l10n.save, style: TextStyle(color: theme.primary)),
            )
          ],
        );
      },
    );
  }

  void _showListActionsSheet(ShoppingListInfo list) {
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
                title: Text(l10n.renameListTitle, style: TextStyle(color: theme.inactive)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditListDialog(list);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.accent),
                title: Text(l10n.delete, style: TextStyle(color: theme.accent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmationDialog(context, list.id, list.name);
                },
              ),
            ],
          ),
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
          style: TextStyle(
              color: theme.secondary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: allListsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text(l10n.error(err.toString()))),
        data: (lists) {
          if (lists.isEmpty) {
            return _buildEmptyState(l10n, theme);
          }
          return _buildSelectList(lists);
        },
      ),
      bottomNavigationBar: allListsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (lists) {
            final isPremium =
                ref.watch(userProfileProvider).value?.isPremium ?? false;
            final listLimit = isPremium ? 6 : 2;
            final canCreateMore = lists.length < listLimit;

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
                      '${l10n.listsLabel} ${lists.length} / $listLimit',
                      style: TextStyle(
                        color: theme.inactive.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (canCreateMore) {
                          _showCreateListSheet();
                        } else if (!isPremium) {
                          showUpgradeDialog(context, ref);
                        }
                      },
                      icon: Icon(canCreateMore ? Icons.add : Icons.lock),
                      label: Text(l10n.createNew),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canCreateMore
                            ? theme.secondary
                            : theme.inactive.withOpacity(0.4),
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
          }),
    );
  }

  // --- THIS IS THE UPDATED WIDGET ---
  Widget _buildEmptyState(AppLocalizations l10n, AppThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Text(
          // For a real app, you would move this string to your AppLocalizations file.
          'Create and manage your shopping lists here.\nTap the "+ Create New" button below to get started.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.inactive.withOpacity(0.8),
            fontSize: 17,
            height: 1.5, // Improves readability for multi-line text
          ),
        ),
      ),
    );
  }

  // ... (_buildSelectList is unchanged)
  Widget _buildSelectList(List<ShoppingListInfo> lists) {
    final theme = ref.watch(themeProvider);
    final activeListId = ref.watch(activeShoppingListProvider);

    // --- 1. GET USER PROFILE TO DETERMINE THE ITEM LIMIT ---
    final userProfile = ref.watch(userProfileProvider).value;
    final isPremium = userProfile?.isPremium ?? false;
    final itemLimit = isPremium ? 60 : 30; // The same limit from your summary bar

    lists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        final isCurrentlyActive = isSelectActiveMode && list.id == activeListId;

        final tileColor = isCurrentlyActive ? theme.secondary : theme.primary;
        final textColor = isCurrentlyActive ? theme.primary : theme.inactive;
        final iconColor = isCurrentlyActive ? theme.primary : theme.inactive;
        final countColor = isCurrentlyActive
            ? theme.primary.withOpacity(0.85)
            : theme.inactive.withOpacity(0.7);

        return Card(
          color: tileColor,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.only(left: 20.0),
            // --- 2. UPDATE THE TITLE TO SHOW THE COUNT IN THE NEW FORMAT ---
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    list.name,
                    style: TextStyle(
                      fontWeight:
                      isCurrentlyActive ? FontWeight.bold : FontWeight.w600,
                      color: textColor,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '[ ${list.itemCount} / $itemLimit ]', // Display as [current / limit]
                  style: TextStyle(
                    color: countColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            onTap: () {
              if (isSelectActiveMode) {
                ref
                    .read(activeShoppingListProvider.notifier)
                    .setActiveList(list.id);
                Navigator.pop(context);
              } else {
                ref.read(shoppingListsProvider.notifier).addToSpecificList(
                    widget.product!, list.id, context);
                widget.onConfirm!(list.name);
              }
            },
            trailing: IconButton(
              icon: Icon(Icons.more_vert, color: iconColor),
              onPressed: () => _showListActionsSheet(list),
            ),
          ),
        );
      },
    );
  }
}