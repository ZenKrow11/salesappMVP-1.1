// lib/components/list_options_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/models/shopping_list_info.dart';
import 'package:sales_app_mvp/pages/manage_custom_items_page.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/pages/shopping_mode_screen.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

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

          // ... (Start Shopping Mode and Manage My Lists are unchanged) ...
          _buildOptionTile(
            context: context,
            theme: theme,
            icon: Icons.shopping_cart_checkout,
            title: 'Start Shopping Mode',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ShoppingModeScreen()));
            },
          ),
          const Divider(),
          _buildOptionTile(
            context: context,
            theme: theme,
            icon: Icons.list_alt,
            title: 'Manage My Lists',
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ShoppingListBottomSheet(),
              );
            },
          ),

          // --- THIS IS THE FIX: This button now launches the new page ---
          _buildOptionTile(
            context: context,
            theme: theme,
            icon: Icons.edit_note,
            title: 'Manage Custom Items',
            onTap: () {
              Navigator.pop(context); // Close the bottom sheet
              // Slide up the new, unified custom items page
              Navigator.of(context).push(SlideUpPageRoute(page: const ManageCustomItemsPage()));
            },
          ),
          // -------------------------------------------------------------

          const Divider(),
          _buildDeleteOption(context, ref, theme),
        ],
      ),
    );
  }

  // ... (The rest of the file remains unchanged. All helper methods are correct.) ...

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

  Widget _buildDeleteOption(
      BuildContext context, WidgetRef ref, AppThemeData theme) {
    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
    final activeListId = ref.watch(activeShoppingListProvider);
    final allLists = ref.watch(allShoppingListsProvider).value ?? [];
    final activeList = allLists.firstWhere(
          (list) => list.id == activeListId,
      orElse: () => ShoppingListInfo(id: '', name: merklisteListName),
    );
    final isDefaultList = activeList.name == merklisteListName;
    final canDelete = isPremium && !isDefaultList;

    return _buildOptionTile(
      context: context,
      theme: theme,
      icon: Icons.delete_outline,
      title: 'Delete Current List',
      color: canDelete ? theme.accent : theme.inactive.withOpacity(0.5),
      onTap: canDelete
          ? () {
        Navigator.pop(context);
        _showDeleteConfirmationDialog(
            context, ref, activeListId, activeList.name);
      }
          : null,
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, String listId, String listName) {
    final firestoreService = ref.read(firestoreServiceProvider);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete "$listName"?'),
          content:
          const Text('This action is permanent and cannot be undone.'),
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
                await firestoreService.deleteList(listId: listId);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}