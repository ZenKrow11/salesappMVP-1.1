import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/filter_provider.dart';
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
                'Filter and Sort',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.inactive),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const Divider(thickness: 1, height: 24),

          // Filter Section (now using ExpansionTiles)
          const Text('FILTERS', style: TextStyle(color: AppColors.inactive,
              fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),

          _buildFilterExpansionTile(
            ref: ref,
            title: 'Store', // Singular title for logic
            options: ref.watch(storeListProvider),
            selectedProvider: storeFilterProvider,
          ),
          const SizedBox(height: 8),
          _buildFilterExpansionTile(
            ref: ref,
            title: 'Category',
            options: ref.watch(categoryListProvider),
            selectedProvider: categoryFilterProvider,
          ),
          const SizedBox(height: 8),
          _buildFilterExpansionTile(
            ref: ref,
            title: 'Subcategory',
            options: ref.watch(subcategoryListProvider),
            selectedProvider: subcategoryFilterProvider,
          ),
          const SizedBox(height: 24),

          // Sort Section
          const Text('SORT BY', style: TextStyle(color: AppColors.inactive,
              fontWeight: FontWeight.bold, fontSize: 12)),
          _buildSortDropdown(ref),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ref.read(storeFilterProvider.notifier).state = [];
                  ref.read(categoryFilterProvider.notifier).state = [];
                  ref.read(subcategoryFilterProvider.notifier).state = [];
                },
                child: const Text('CLEAR ALL', style: TextStyle(color: AppColors.inactive,
                    fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DONE', style: TextStyle(color: AppColors.inactive,
                      fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Helper for expandable filter sections with fixed height
  Widget _buildFilterExpansionTile({
    required WidgetRef ref,
    required String title,
    required List<String> options,
    required StateProvider<List<String>> selectedProvider,
  }) {
    final selectedItems = ref.watch(selectedProvider);

    if (options.isEmpty && title != 'Store') {
      return const SizedBox.shrink();
    }

    // Determine the text for the collapsed tile
    String getTitleText() {
      if (selectedItems.isEmpty) {
        return 'All ${title}s';
      } else if (selectedItems.length == 1) {
        return selectedItems.first;
      } else {
        return '${title}s (${selectedItems.length} selected)';
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.inactive.withValues(alpha: 0.5)),
      ),
      child: ExpansionTile(
        title: Text(
          getTitleText(),
          style: const TextStyle(color: AppColors.inactive,
              fontWeight: FontWeight.normal),
        ),
        collapsedIconColor: AppColors.inactive,
        iconColor: AppColors.accent,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          // Cap the height of the expanded content to 250px with a scrollable list
          Container(
            constraints: const BoxConstraints(maxHeight: 250.0),
            child: SingleChildScrollView(
              child: Column(
                children: options.map((item) {
                  return CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(item, style: const TextStyle(color: AppColors.primary)),
                    value: selectedItems.contains(item),
                    onChanged: (bool? isSelected) {
                      final currentSelection = List<String>.from(ref.read(selectedProvider));
                      if (isSelected == true) {
                        currentSelection.add(item);
                      } else {
                        currentSelection.remove(item);
                      }
                      ref.read(selectedProvider.notifier).state = currentSelection;
                    },
                    activeColor: AppColors.accent,
                    checkColor: AppColors.primary,
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for sort dropdown (unchanged)
  Widget _buildSortDropdown(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.inactive.withValues(alpha: 0.5)),
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