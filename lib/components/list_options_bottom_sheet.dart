// lib/components/list_options_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/pages/shopping_mode_screen.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

import '../pages/manage_custom_items_page.dart';
import '../widgets/slide_up_page_route.dart';

class ListOptionsBottomSheet extends ConsumerWidget {
  const ListOptionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, theme),
          const SizedBox(height: 16),

          // Group 1: Execution
          _buildOptionTile(
            context: context,
            theme: theme,
            icon: Icons.shopping_cart_checkout,
            title: 'Start Shopping Mode',
            onTap: () {
              Navigator.pop(context); // Close this sheet first
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingModeScreen()));
            },
          ),
          const Divider(),

          // Group 2: Management
          _buildOptionTile(
            context: context,
            theme: theme,
            icon: Icons.list_alt,
            title: 'Manage My Lists',
            onTap: () {
              Navigator.pop(context); // Close this sheet
              // Open the existing, powerful sheet for list management
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent, // Let the child handle color
                builder: (_) => const ShoppingListBottomSheet(),
              );
            },
          ),
          _buildOptionTile(
            context: context,
            theme: theme,
            icon: Icons.edit_note,
            title: 'Manage Custom Items',
              onTap: () {
                Navigator.pop(context); // Close the options sheet
                // Slide up the new page
                Navigator.of(context).push(SlideUpPageRoute(page: const ManageCustomItemsPage()));
              },

          ),
          const Divider(),

          // Group 3: Danger Zone
          _buildDeleteOption(context, ref, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'List Options',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.secondary,
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: theme.accent),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required AppThemeData theme,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? theme.inactive),
      title: Text(title, style: TextStyle(color: color ?? theme.inactive)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildDeleteOption(BuildContext context, WidgetRef ref, AppThemeData theme) {
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
    final activeListId = ref.watch(activeShoppingListProvider);
    final allLists = ref.watch(allShoppingListsProvider).value ?? [];

    // Find the active list, defaulting to the base "Merkliste" if something goes wrong
    final activeList = allLists.firstWhere(
          (list) => list.id == activeListId,
      orElse: () => ShoppingListInfo(id: '', name: merklisteListName),
    );
    final isDefaultList = activeList.name == merklisteListName;

    // A user can delete a list if they are premium AND it's not the default list.
    final canDelete = isPremium && !isDefaultList;

    return _buildOptionTile(
      context: context,
      theme: theme,
      icon: Icons.delete_outline,
      title: 'Delete Current List',
      color: canDelete ? theme.accent : theme.inactive.withOpacity(0.5),
      onTap: canDelete ? () {
        Navigator.pop(context); // Close bottom sheet
        _showDeleteConfirmationDialog(context, ref, activeListId, activeList.name);
      } : null, // Disable the button if it can't be deleted
    );
  }

  // This helper is moved from the shopping_list_page to make this component self-contained.
  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, String listId, String listName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete "$listName"?'),
          content: const Text('This action is permanent and cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await ref.read(firestoreServiceProvider).deleteList(listId: listId);
                // The shopping_list_page will automatically handle the list state change.
              },
            ),
          ],
        );
      },
    );
  }
}