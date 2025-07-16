// lib/widgets/sort_button_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart'; // Imports SortOption and its extension
import 'package:sales_app_mvp/providers/filter_state_provider.dart'; // Imports the provider
import 'package:sales_app_mvp/widgets/theme_color.dart'; // Assuming this holds your AppColors

/// A modular button that displays the current sort option and allows changing it via a dropdown.
class SortButton extends ConsumerWidget {
  const SortButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We only need the notifier to make changes
    final filterNotifier = ref.read(filterStateProvider.notifier);

    return PopupMenuButton<SortOption>(
      onSelected: (newSortOption) {
        // Update the state when a new option is chosen
        filterNotifier.update((state) => state.copyWith(sortOption: newSortOption));
      },
      itemBuilder: (context) {
        // This now works perfectly because `displayName` is imported from filter_state.dart
        return SortOption.values.map((option) {
          return PopupMenuItem<SortOption>(
            value: option,
            child: Text(option.displayName),
          );
        }).toList();
      },
      color: AppColors.background, // Example color
      // The child is the button that the user sees and taps
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: AppColors.primary, // Example color
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sort, color: AppColors.secondary, size: 24.0),
            const SizedBox(width: 8),
            // --- FIX: The illegal `Expanded` widget is removed to solve the layout error. ---
            const Text(
              'Sort',
              style: TextStyle(color: AppColors.inactive),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}