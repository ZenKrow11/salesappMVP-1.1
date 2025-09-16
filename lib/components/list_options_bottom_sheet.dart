// lib/components/list_options_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/pages/manage_custom_items_page.dart';
import 'package:sales_app_mvp/pages/shopping_mode_screen.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';

class ListOptionsBottomSheet extends ConsumerWidget {
  const ListOptionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, theme),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOptionButton(
                  theme: theme,
                  icon: Icons.shopping_cart_checkout,
                  label: 'Shopping Mode',
                  onTap: () {
                    // FIX: Correctly navigates to the ShoppingModeScreen
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ShoppingModeScreen()));
                  },
                ),
                _buildOptionButton(
                  theme: theme,
                  icon: Icons.list_alt,
                  label: 'Manage Lists',
                  onTap: () {
                    // FIX: Correctly shows the ShoppingListBottomSheet
                    Navigator.pop(context); // Close this sheet first
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => const ShoppingListBottomSheet(),
                    );
                  },
                ),
                _buildOptionButton(
                  theme: theme,
                  icon: Icons.edit_note, // Changed from basket to match old version
                  label: 'Manage Items',
                  onTap: () {
                    // FIX: Correctly navigates to ManageCustomItemsPage
                    final activeListId = ref.read(activeShoppingListProvider);
                    Navigator.pop(context); // Close this sheet first
                    Navigator.of(context).push(SlideUpPageRoute(
                      page: ManageCustomItemsPage(listId: activeListId),
                    ));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
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
        )
      ],
    );
  }

  Widget _buildOptionButton({
    required AppThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.secondary),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: theme.inactive,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}