// lib/widgets/filter_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/filter_bottom_sheet.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class FilterButton extends ConsumerWidget {
  const FilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isFilterActive = ref.watch(filterStateProvider.select((f) => f.isFilterActive));

    return ElevatedButton.icon(
      icon: Icon(Icons.filter_alt, color: theme.secondary, size: 22.0),
      label: Row(
        children: [
          Expanded(
            child: Text(
              'Filter',
              style: TextStyle(color: theme.inactive),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isFilterActive)
            _ClearButton(
              onPressed: () {
                ref.read(filterStateProvider.notifier).update((state) => state.copyWith(
                  selectedStores: [],
                  selectedCategories: [],
                  selectedSubcategories: [],
                ));
              },
            ),
        ],
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const FilterBottomSheet(),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.background.withOpacity(0.5),
        // Adjust horizontal padding
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }
}

// Helper widget for the clear button
class _ClearButton extends ConsumerWidget {
  final VoidCallback onPressed;
  const _ClearButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: theme.accent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.close, color: theme.inactive, size: 12),
      ),
    );
  }
}