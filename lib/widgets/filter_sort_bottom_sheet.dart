import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/filter_providers.dart';
import 'package:sales_app_mvp/providers/sort_provider.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class FilterSortBottomSheet extends ConsumerWidget {
  const FilterSortBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make column height fit content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.inactive),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const Divider(thickness: 1, height: 24),

          // Filter Section
          const Text('FILTERS', style: TextStyle(color: AppColors.inactive, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          _buildFilterDropdown(
            ref: ref,
            hint: 'Store',
            value: ref.watch(storeFilterProvider),
            items: ref.watch(storeListProvider),
            onChanged: (value) => ref.read(storeFilterProvider.notifier).state = value,
          ),
          const SizedBox(height: 8),
          _buildFilterDropdown(
            ref: ref,
            hint: 'Category',
            value: ref.watch(categoryFilterProvider),
            items: ref.watch(categoryListProvider),
            onChanged: (value) => ref.read(categoryFilterProvider.notifier).state = value,
          ),
          const SizedBox(height: 8),
          _buildFilterDropdown(
            ref: ref,
            hint: 'Subcategory',
            value: ref.watch(subcategoryFilterProvider),
            items: ref.watch(subcategoryListProvider),
            onChanged: (value) => ref.read(subcategoryFilterProvider.notifier).state = value,
          ),
          const SizedBox(height: 24),

          // Sort Section
          const Text('SORT BY', style: TextStyle(color: AppColors.inactive, fontWeight: FontWeight.bold, fontSize: 12)),
          _buildSortDropdown(ref),
          const SizedBox(height: 24),

          // Done Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context); // Close the bottom sheet
              },
              child: const Text('DONE', style: TextStyle(color: AppColors.inactive, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10), // Padding for gesture area
        ],
      ),
    );
  }

  // Helper for filter dropdowns
  Widget _buildFilterDropdown({
    required WidgetRef ref,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    if (items.isEmpty && hint != 'Store') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.inactive.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: const TextStyle(color: AppColors.inactive)),
          iconEnabledColor: AppColors.primary,
          dropdownColor: AppColors.background,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('All ${hint}s', style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.inactive)),
            ),
            ...items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(color: AppColors.primary)),
              );
            }).toList(),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Helper for sort dropdown
  Widget _buildSortDropdown(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.inactive.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortOption>(
          isExpanded: true,
          value: ref.watch(sortOptionProvider),
          iconEnabledColor: AppColors.primary,
          dropdownColor: AppColors.primary,
          items: SortOption.values.map((SortOption option) {
            return DropdownMenuItem<SortOption>(
              value: option,
              child: Text(option.name, style: const TextStyle(color: AppColors.inactive)),
            );
          }).toList(),
          onChanged: (SortOption? newValue) {
            if (newValue != null) {
              ref.read(sortOptionProvider.notifier).state = newValue;
            }
          },
        ),
      ),
    );
  }
}

// Remember to add this extension to the file or a shared location if you haven't already.
extension SortOptionExtension on SortOption {
  String get name {
    switch (this) {
      case SortOption.alphabeticalStore:
        return 'By Store';
      case SortOption.alphabetical:
        return 'A-Z';
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.discountHighToLow:
        return 'Discount: High to Low';
    }
  }
}