// lib/components/shopping_list_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import '../models/shopping_list_info.dart';
import '../models/product.dart';
import '../providers/shopping_list_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/app_theme.dart';
import '../providers/user_profile_provider.dart';
import '../components/upgrade_dialog.dart';

class ShoppingListBottomSheet extends ConsumerStatefulWidget {
  final Product? product;
  final void Function(String selectedListName)? onConfirm;
  final int initialTabIndex;

  const ShoppingListBottomSheet({
    super.key,
    this.product,
    this.onConfirm,
    this.initialTabIndex = 0,
  }) : assert(product == null || onConfirm != null,
  'onConfirm must be provided when a product is given');

  @override
  ConsumerState<ShoppingListBottomSheet> createState() =>
      _ShoppingListBottomSheetState();
}

class _ShoppingListBottomSheetState extends ConsumerState<ShoppingListBottomSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _newListController = TextEditingController();
  TabController? _tabController;

  bool get isSelectActiveMode => widget.product == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _newListController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  // 2. LOCALIZE ALL HELPER METHODS THAT SHOW UI TEXT
  void _addAndDismiss() {
    final l10n = AppLocalizations.of(context)!;
    if (widget.product == null) return;
    ref.read(shoppingListsProvider.notifier).addToList(widget.product!, context);
    widget.onConfirm!(merklisteListName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.addedTo(merklisteListName))),
    );
    Navigator.of(context).pop();
  }

  void _createAndSetActive(String listName) {
    final l10n = AppLocalizations.of(context)!;
    if (listName.trim().isEmpty) return;
    final trimmedName = listName.trim();
    ref.read(shoppingListsProvider.notifier).createNewList(trimmedName);
    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    // 3. GET THE l10n OBJECT IN THE MAIN BUILD METHOD
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 4. PASS l10n TO ALL HELPER WIDGETS
                _buildHeader(l10n),
                const SizedBox(height: 12),
                _buildTabBar(l10n),
                const SizedBox(height: 16),
                Flexible(
                  child: TabBarView(
                    controller: _tabController!,
                    children: [
                      _buildSelectList(l10n),
                      _buildNewListTab(l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final theme = ref.watch(themeProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.manageMyLists,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.secondary),
        ),
        IconButton(
          icon: Icon(Icons.close, color: theme.accent),
          onPressed: () => Navigator.pop(context),
        )
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;

    return TabBar(
      controller: _tabController!,
      labelColor: theme.secondary,
      unselectedLabelColor: theme.inactive,
      indicatorColor: theme.secondary,
      dividerColor: Colors.transparent,
      tabs: [
        Tab(text: l10n.myLists),
        Tab(
          child: Text(
            l10n.createNew,
            style: TextStyle(
              color: isPremium ? null : theme.inactive.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectList(AppLocalizations l10n) {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
    final activeListId = ref.watch(activeShoppingListProvider);

    if (!isPremium) {
      return ListTile(
        title: Text(merklisteListName, style: TextStyle(color: theme.inactive)),
        onTap: () {
          if (isSelectActiveMode) {
            ref.read(activeShoppingListProvider.notifier).setActiveList(merklisteListName);
            Navigator.pop(context);
          } else {
            _addAndDismiss();
          }
        },
        tileColor: theme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    }

    final allListsAsync = ref.watch(allShoppingListsProvider);

    return allListsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(l10n.error(err.toString()))),
      data: (lists) {
        if (lists.isEmpty) {
          return Center(child: Text(l10n.defaultListIsBeingPrepared));
        }

        // ... (sorting logic remains unchanged)
        ShoppingListInfo? defaultList;
        List<ShoppingListInfo> customLists = [];
        for (var list in lists) {
          if (list.name == merklisteListName) {
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
          itemCount: orderedLists.length,
          itemBuilder: (context, index) {
            final list = orderedLists[index];
            final isCurrentlyActive = isSelectActiveMode && list.id == activeListId;
            final isDefaultList = list.name == merklisteListName;

            return Card(
              elevation: isCurrentlyActive ? 2 : 0,
              color: isCurrentlyActive
                  ? theme.secondary.withOpacity(0.9)
                  : theme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(
                  list.name,
                  style: TextStyle(
                    fontWeight: isCurrentlyActive ? FontWeight.bold : FontWeight.normal,
                    color: isCurrentlyActive ? theme.primary : theme.inactive,
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
                  icon: Icon(
                    Icons.delete_outline,
                    color: isCurrentlyActive ? theme.primary : theme.accent,
                  ),
                  onPressed: () {
                    _showDeleteConfirmationDialog(context, list.id, list.name);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNewListTab(AppLocalizations l10n) {
    final theme = ref.watch(themeProvider);
    final isPremium = ref.watch(isPremiumProvider);

    if (isPremium) {
      final allListsAsync = ref.watch(allShoppingListsProvider);

      return allListsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.error(err.toString()))),
        data: (lists) {
          const int maxPremiumLists = 9;
          final canCreateMoreLists = lists.length < maxPremiumLists;

          if (canCreateMoreLists) {
            // ========== THE FIX IS HERE ==========
            // Wrap the Column in a SingleChildScrollView to prevent overflow
            // when the keyboard appears.
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _newListController,
                    autofocus: _tabController?.index == 1,
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.secondary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _createAndSetActive(_newListController.text),
                    child: Text(
                      l10n.createAndSelect,
                      style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
            // ========== END OF FIX ==========
          } else {
            // This part for 'max lists reached' is fine and doesn't need to scroll.
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: theme.inactive.withOpacity(0.7)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.maximumListsReached(maxPremiumLists),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: theme.inactive),
                  ),
                ],
              ),
            );
          }
        },
      );
    } else {
      // The paywall UI for free users is also fine and doesn't need to scroll.
      return InkWell(
        onTap: () {
          Navigator.of(context).pop(); // Close the current sheet
          showUpgradeDialog(context, ref); // Show the main upgrade dialog
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 48, color: theme.inactive.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                l10n.premiumFeatureListsTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.inactive),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.premiumFeatureListsBody,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: theme.inactive.withOpacity(0.7)),
              ),
              const SizedBox(height: 24),
              // AbsorbPointer prevents the button's own tap effect from conflicting with the InkWell
              AbsorbPointer(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.star, color: theme.primary),
                  label: Text(l10n.upgradeNow, style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: theme.secondary),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}