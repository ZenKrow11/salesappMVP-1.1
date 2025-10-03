// lib/components/list_options_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/pages/manage_custom_items_page.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';

class ListOptionsBottomSheet extends ConsumerWidget {
  const ListOptionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    // 2. GET THE LOCALIZATIONS OBJECT
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 3. PASS l10n TO HELPER METHODS
            _buildHeader(context, theme, l10n),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    context: context,
                    theme: theme,
                    icon: Icons.list_alt_rounded,
                    // 4. REPLACE HARDCODED TEXT
                    label: l10n.manageLists,
                    onTap: () {
                      Navigator.pop(context);
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
                    label: l10n.customItems,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context, rootNavigator: true).push(
                        SlideUpPageRoute(page: const ManageCustomItemsPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // UPDATE SIGNATURE TO ACCEPT l10n
  Widget _buildHeader(BuildContext context, AppThemeData theme, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.listOptions,
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

  // No changes needed here, as it receives the localized label
  Widget _buildOptionButton({
    required BuildContext context,
    required AppThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    // ... (This method remains unchanged)
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
}