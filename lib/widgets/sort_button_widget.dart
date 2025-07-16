import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

/// Provides a user-friendly display name for each sort option.
extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.storeAlphabetical:
        return 'Store: A-Z';
      case SortOption.productAlphabetical:
        return 'Product: A-Z';
      case SortOption.discountHighToLow:
        return 'Discount: High-Low';
      case SortOption.discountLowToHigh:
        return 'Discount: Low-High';
      case SortOption.priceHighToLow:
        return 'Price: High-Low';
      case SortOption.priceLowToHigh:
        return 'Price: Low-High';

    }
  }
}

/// A modular button that displays the current sort option and allows changing it via a dropdown.
class SortButton extends ConsumerWidget {
  const SortButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSortOption = ref.watch(filterStateProvider.select((s) => s.sortOption));
    final filterNotifier = ref.read(filterStateProvider.notifier);

    return PopupMenuButton<SortOption>(
      onSelected: (newSortOption) {
        filterNotifier.update((state) => state.copyWith(sortOption: newSortOption));
      },
      itemBuilder: (context) {
        return SortOption.values.map((option) {
          return PopupMenuItem<SortOption>(
            value: option,
            child: Text(option.displayName),
          );
        }).toList();
      },
      color: AppColors.background,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sort, color: AppColors.secondary, size: 24.0),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sort',
                style: const TextStyle(color: AppColors.inactive),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}