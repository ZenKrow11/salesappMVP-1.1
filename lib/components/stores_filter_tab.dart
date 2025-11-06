// lib/components/stores_filter_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import 'package:sales_app_mvp/providers/filter_options_provider.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class StoresFilterTab extends ConsumerWidget {
  final bool isIncludeMode;
  final Set<String> tappedStores;
  final void Function(String store) onToggleStore;
  final VoidCallback onToggleMode;

  const StoresFilterTab({
    super.key,
    required this.isIncludeMode,
    required this.tappedStores,
    required this.onToggleStore,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStoreOptions = ref.watch(storeOptionsProvider);
    final theme = ref.watch(themeProvider);
    // 2. GET THE LOCALIZATIONS OBJECT
    final l10n = AppLocalizations.of(context)!;

    return asyncStoreOptions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      // 3. REPLACE THE HARDCODED ERROR TEXT
      error: (err, stack) => Center(child: Text(l10n.error(err.toString()))),
      data: (storeOptions) {
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          // --- CHANGE: Updated grid delegate to match the 'Organize List' style ---
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          // --- CHANGE: Removed the '+ 1' to hide the toggle button ---
          itemCount: storeOptions.length,
          itemBuilder: (context, index) {
            // --- CHANGE: Commented out the logic for the toggle button ---
            // if (index == storeOptions.length) {
            //   return _buildModeToggleTile(theme);
            // }

            final store = storeOptions[index];
            final isSelected = tappedStores.contains(store);
            final selectionColor =
            isIncludeMode ? theme.secondary : theme.accent;

            return GestureDetector(
              onTap: () => onToggleStore(store),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(12), // Adjusted for consistency
                      border: Border.all(
                        color:
                        isSelected ? selectionColor : Colors.transparent,
                        width: 3, // Adjusted for consistency
                      ),
                    ),
                    child: Center(
                        child: StoreLogo(storeName: store, height: 40)),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        isIncludeMode
                            ? Icons.check_box
                            : Icons.do_not_disturb_on,
                        color: selectionColor,
                        size: 22,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- CHANGE: This helper method is now unused, but kept for potential future use ---
  // This helper method has no text, so it remains unchanged.
  Widget _buildModeToggleTile(AppThemeData theme) {
    final iconData = isIncludeMode ? Icons.add_circle : Icons.remove_circle;
    final iconColor = isIncludeMode ? theme.secondary : theme.accent;

    return GestureDetector(
      onTap: onToggleMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor, width: 2.0),
        ),
        child: Center(
          child: Icon(iconData, color: iconColor, size: 36),
        ),
      ),
    );
  }
}