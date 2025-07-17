// lib/widgets/sort_button_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

/// A button that opens a custom, styled bottom sheet for changing the sort order.
class SortButton extends ConsumerWidget {
  const SortButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This button now triggers a custom modal sheet, matching the app's aesthetic.
    return TextButton.icon(
      icon: const Icon(Icons.sort, color: AppColors.secondary, size: 24.0),
      label: const Text(
        'Sort',
        style: TextStyle(color: AppColors.inactive),
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          backgroundColor: Colors.transparent, // Important for custom shape
          builder: (_) => const _SortOptionsBottomSheet(),
        );
      },
      style: TextButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
    );
  }
}

/// The private widget for the content of the bottom sheet.
/// This keeps the main `SortButton` widget clean and focused.
class _SortOptionsBottomSheet extends ConsumerWidget {
  const _SortOptionsBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterStateProvider);
    final filterNotifier = ref.read(filterStateProvider.notifier);
    final currentSortOption = filterState.sortOption;

    // The main container that provides the background and rounded corners.
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
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
            // A clear header for the sheet.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.accent),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Dynamically create a list of sort options.
            ...SortOption.values.map((option) {
              final bool isSelected = option == currentSortOption;

              // Use a styled ListTile for a consistent look and feel.
              return Card(
                elevation: 0,
                color: isSelected ? AppColors.secondary : Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    option.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      // The text color logic you requested.
                      color: isSelected ? AppColors.primary : AppColors.inactive,
                    ),
                  ),
                  onTap: () {
                    // Update the state with the chosen option.
                    filterNotifier.update((state) => state.copyWith(sortOption: option));
                    // Close the bottom sheet after selection.
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}