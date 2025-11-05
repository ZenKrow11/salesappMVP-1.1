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

class _ManageShoppingListsPageState extends ConsumerState<ManageShoppingListsPage> {
  final TextEditingController _newListController = TextEditingController();

  // This logic remains the same: it determines if we are just managing lists
  // or selecting a list to add an item to.
  bool get isSelectActiveMode => widget.product == null;

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }


  // === REFACTORED: This method is now simpler and more robust. ===
  void _createNewList(String listName) {
    if (listName.trim().isEmpty) return;

    final trimmedName = listName.trim();
    // We call the notifier to create the list. The notifier itself handles
    // the business logic (like checking limits).
    ref.read(shoppingListsProvider.notifier).createNewList(trimmedName).catchError((e) {
      // If the notifier throws an error (e.g., limit reached), show it to the user.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    });

    // Close the dialog. The UI will update automatically when the provider state changes.
    // We no longer manually set the active list here. The provider handles it.
    if(Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // === REFACTORED: Now calls the correct notifier method for deletion. ===
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
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // CORRECT: Call the notifier, not FirestoreService directly.
                // This ensures all app state (like the active list) is updated correctly.
                ref.read(shoppingListsProvider.notifier).deleteList(listId);
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
            onSubmitted: _createNewList, // Use the new, corrected method
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
              onPressed: () => _createNewList(_newListController.text), // Use the new, corrected method
              child: Text(l10n.create, style: TextStyle(color: theme.primary)), // Changed text to be more generic
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
      // === REFACTORED: Body logic is now much simpler. ===
      body: allListsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.error(err.toString()))),
        data: (lists) {
          // If there are no lists at all, show the empty state.
          if (lists.isEmpty) {
            return _buildEmptyState(l10n, theme);
          }
          // Otherwise, build the list of lists.
          return _buildSelectList(l10n, lists);
        },
      ),
      // === REFACTORED: Bottom bar uses the new architecture rules. ===
      bottomNavigationBar: allListsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (lists) {
            final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
            // CORRECT: Use the new limits defined in our project plan.
            final listLimit = isPremium ? 6 : 2;
            final canCreateMore = lists.length < listLimit;

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
                      '${l10n.listsLabel} ${lists.length} / $listLimit',
                      style: TextStyle(
                        color: theme.inactive.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      // The button is enabled if the user can create more.
                      // If they are a free user at their limit, prompt them to upgrade.
                      onPressed: () {
                        if (canCreateMore) {
                          _showCreateListDialog();
                        } else if (!isPremium) {
                          showUpgradeDialog(context, ref);
                        }
                        // If they are premium and at the limit, onPressed will be null, disabling the button.
                      },
                      icon: Icon(canCreateMore ? Icons.add : Icons.lock),
                      label: Text(l10n.createNew),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canCreateMore
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
          l10n.shoppingListsEmpty, // You might want a new l10n string like "You have no lists yet."
          textAlign: TextAlign.center,
          style: TextStyle(
              color: theme.inactive.withOpacity(0.7), fontSize: 16),
        ),
      ),
    );
  }

  // === REFACTORED: This widget is now clean and simple. ===
  Widget _buildSelectList(AppLocalizations l10n, List<ShoppingListInfo> lists) {
    final theme = ref.watch(themeProvider);
    final activeListId = ref.watch(activeShoppingListProvider);

    // All special logic for a "default list" is gone.
    // We just sort all lists alphabetically.
    lists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        final isCurrentlyActive = isSelectActiveMode && list.id == activeListId;

        // The check for `isDefaultList` is gone.

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
              // Set the tapped list as the new active list.
              ref.read(activeShoppingListProvider.notifier).setActiveList(list.id);
              Navigator.pop(context);
            } else {
              // This is the "select a list" mode.
              ref.read(shoppingListsProvider.notifier).addToSpecificList(widget.product!, list.id, context);
              widget.onConfirm!(list.name);
            }
          },
          // ALL lists are now deletable. The trailing icon is always a delete button.
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: theme.accent),
            onPressed: () => _showDeleteConfirmationDialog(context, list.id, list.name),
          ),
        );
      },
    );
  }
}