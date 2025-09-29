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
            Column(
              children: [
                // Top Row of the Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildOptionButton(
                        context: context,
                        theme: theme,
                        icon: Icons.list_alt_rounded,
                        label: 'Manage Lists',
                        onTap: () {
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOptionButton(
                        context: context,
                        theme: theme,
                        icon: Icons.add_box_outlined,
                        label: 'Custom Items',
                        onTap: () {
                          Navigator.pop(context); // Close this sheet first
                          Navigator.of(context, rootNavigator: true).push(
                            SlideUpPageRoute(page: const ManageCustomItemsPage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Bottom Row of the Grid
                Row(
                  children: [
                    // The new View Mode Toggle
                    Expanded(child: _buildViewModeToggle(context, ref, theme)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOptionButton(
                        context: context,
                        theme: theme,
                        icon: Icons.shopping_cart_checkout_rounded,
                        label: 'Shopping Mode',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ShoppingModeScreen()));
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeData theme) {
    // This method remains unchanged
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
    required BuildContext context,
    required AppThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    // This helper method remains unchanged
    return Material(
      color: theme.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.secondary, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.inactive, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================================================================
  // ===== FIX: Replaced the 'slider' with a single toggle button =====
  // ====================================================================
  Widget _buildViewModeToggle(BuildContext context, WidgetRef ref, AppThemeData theme) {
    // 1. Watch the current view mode state.
    final isGridView = ref.watch(shoppingListViewModeProvider);

    // 2. Determine which icon and label to show based on the current state.
    final IconData currentIcon = isGridView ? Icons.grid_view_rounded : Icons.view_list_rounded;
    final String currentLabel = isGridView ? 'Grid View' : 'List View';

    // 3. Use the same structure as _buildOptionButton for a consistent UI.
    return Material(
      color: theme.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        // 4. When tapped, update the provider's state to the opposite value.
        onTap: () {
          ref.read(shoppingListViewModeProvider.notifier).state = !isGridView;
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use the dynamic icon
              Icon(currentIcon, color: theme.secondary, size: 32),
              const SizedBox(height: 8),
              // Use the dynamic label for clarity
              Text(
                currentLabel,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.inactive, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}