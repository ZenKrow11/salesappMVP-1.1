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
          backgroundColor: Colors.transparent,
          // ===================================================================
          // === KEY CHANGE 1: Allow the sheet to grow to fit its content    ===
          // ===================================================================
          isScrollControlled: true,
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
class _SortOptionsBottomSheet extends ConsumerWidget {
  const _SortOptionsBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterStateProvider);
    final filterNotifier = ref.read(filterStateProvider.notifier);
    final currentSortOption = filterState.sortOption;

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
        // ===================================================================
        // === KEY CHANGE 2: Wrap the Column in a scroll view              ===
        // ===================================================================
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              ...SortOption.values.map((option) {
                final bool isSelected = option == currentSortOption;

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
                        color: isSelected ? AppColors.primary : AppColors.inactive,
                      ),
                    ),
                    onTap: () {
                      filterNotifier.update((state) => state.copyWith(sortOption: option));
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}