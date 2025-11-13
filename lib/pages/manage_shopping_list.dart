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

  const ManageShoppingListsPage({
    super.key,
    this.product,
  });

  @override
  ConsumerState<ManageShoppingListsPage> createState() =>
      _ManageShoppingListsPageState();
}

class _ManageShoppingListsPageState
    extends ConsumerState<ManageShoppingListsPage> {
  final TextEditingController _listNameController = TextEditingController();

  bool get isSelectMode => widget.product != null;

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  void _createNewList(String listName) {
    if (listName.trim().isEmpty) return;
    final trimmedName = listName.trim();
    ref
        .read(shoppingListsProvider.notifier)
        .createNewList(trimmedName)
        .catchError((e) {
      // --- FIX: Add mounted check before using context in async gap ---
      if (!mounted) return;
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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.deleteListConfirmationTitle(listName),
              style: TextStyle(
                  color: theme.secondary, fontWeight: FontWeight.bold)),
          content: Text(l10n.deleteListConfirmationBody,
              style: TextStyle(color: theme.inactive)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.inactive,
                // --- FIX: Replaced deprecated withOpacity with withAlpha ---
                side: BorderSide(color: theme.inactive.withAlpha((255 * 0.5).round())),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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

  void _showListNameInputSheet({
    required String title,
    required String buttonText,
    required String hintText,
    required void Function(String) onSubmit,
    String initialValue = '',
  }) {
    final theme = ref.read(themeProvider);
    _listNameController.text = initialValue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: theme.secondary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _listNameController,
                  autofocus: true,
                  style: TextStyle(color: theme.inactive),
                  onSubmitted: onSubmit,
                  decoration: InputDecoration(
                    labelText: hintText,
                    labelStyle:
                    // --- FIX: Replaced deprecated withOpacity with withAlpha ---
                    TextStyle(color: theme.inactive.withAlpha((255 * 0.7).round())),
                    filled: true,
                    fillColor: theme.primary,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.secondary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: theme.secondary,
                      minimumSize: const Size(double.infinity, 50)),
                  onPressed: () => onSubmit(_listNameController.text),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                )
              ],
            ),
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
                        // --- FIX: Replaced deprecated withOpacity with withAlpha ---
                        color: theme.inactive.withAlpha((255 * 0.8).round()),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (canCreateMore) {
                          _showListNameInputSheet(
                            title: l10n.createNew,
                            buttonText: l10n.create,
                            hintText: l10n.enterNewListName,
                            onSubmit: _createNewList,
                          );
                        } else if (!isPremium) {
                          showUpgradeDialog(context, ref);
                        }
                      },
                      icon: Icon(canCreateMore ? Icons.add : Icons.lock),
                      label: Text(l10n.createNew),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canCreateMore
                            ? theme.secondary
                        // --- FIX: Replaced deprecated withOpacity with withAlpha ---
                            : theme.inactive.withAlpha((255 * 0.4).round()),
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

  Widget _buildEmptyState(AppLocalizations l10n, AppThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Text(
          'Create and manage your shopping lists here.\nTap the "+ Create New" button below to get started.',
          textAlign: TextAlign.center,
          style: TextStyle(
            // --- FIX: Replaced deprecated withOpacity with withAlpha ---
            color: theme.inactive.withAlpha((255 * 0.8).round()),
            fontSize: 17,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectList(List<ShoppingListInfo> lists) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    final activeListId = ref.watch(activeShoppingListProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final isPremium = userProfile?.isPremium ?? false;
    final itemLimit = isPremium ? 60 : 30;

    lists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        final isCurrentlyActive = !isSelectMode && list.id == activeListId;

        final tileColor = isCurrentlyActive ? theme.secondary : theme.primary;
        final textColor = isCurrentlyActive ? theme.primary : theme.inactive;
        final iconColor = isCurrentlyActive ? theme.primary : theme.inactive;
        // --- FIX: Replaced deprecated withOpacity with withAlpha on both sides ---
        final countColor = isCurrentlyActive
            ? theme.primary.withAlpha((255 * 0.85).round())
            : theme.inactive.withAlpha((255 * 0.7).round());

        return Card(
          color: tileColor,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.only(left: 20.0),
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
                  '[ ${list.itemCount} / $itemLimit ]',
                  style: TextStyle(
                    color: countColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            onTap: () {
              if (isSelectMode) {
                ref.read(shoppingListsProvider.notifier).addToSpecificList(
                    widget.product!, list.id);
                Navigator.pop(context, list.name);
              } else {
                ref
                    .read(activeShoppingListProvider.notifier)
                    .setActiveList(list.id);
                Navigator.pop(context);
              }
            },
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: iconColor),
              color: theme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'rename') {
                  _showListNameInputSheet(
                    title: l10n.renameListTitle,
                    buttonText: l10n.save,
                    hintText: l10n.listNameLabel,
                    initialValue: list.name,
                    onSubmit: (newName) => _renameList(list.id, newName),
                  );
                } else if (value == 'delete') {
                  _showDeleteConfirmationDialog(context, list.id, list.name);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined, color: theme.inactive),
                    title: Text(l10n.renameListTitle,
                        style: TextStyle(color: theme.inactive)),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: theme.accent),
                    title:
                    Text(l10n.delete, style: TextStyle(color: theme.accent)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}