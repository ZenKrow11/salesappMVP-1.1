import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/filter_provider.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

// Extension to make dropdown labels user-friendly. This assumes your real
// SortOption enum is in filter_state.dart
extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
    // Use your actual enum values from filter_state.dart
      case SortOption.alphabetical:
        return 'Alphabetical';
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.discountHighToLow:
        return 'Discount: High to Low';
    }
  }
}


class FilterSortBottomSheet extends ConsumerWidget {
  const FilterSortBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeOptions = ref.watch(storeOptionsProvider);
    final categoryOptions = ref.watch(categoryOptionsProvider);
    final subcategoryOptions = ref.watch(subcategoryOptionsProvider);
    final currentFilterState = ref.watch(filterStateProvider);
    final filterNotifier = ref.read(filterStateProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter and Sort', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => filterNotifier.state = const FilterState(),
                  child: const Text('Reset', style: TextStyle(color: AppColors.secondary)),
                ),
              ],
            ),
            const Divider(height: 24),
            _FilterSectionWidget(
              title: 'Store',
              options: storeOptions,
              selectedOptions: currentFilterState.selectedStores,
              onSelected: (store) {
                final currentSelection = List<String>.from(currentFilterState.selectedStores);
                if (currentSelection.contains(store)) {
                  currentSelection.remove(store);
                } else {
                  currentSelection.add(store);
                }
                filterNotifier.state = currentFilterState.copyWith(selectedStores: currentSelection);
              },
            ),
            _FilterSectionWidget(
              title: 'Category',
              options: categoryOptions,
              selectedOptions: currentFilterState.selectedCategories,
              onSelected: (category) {
                final currentSelection = List<String>.from(currentFilterState.selectedCategories);
                if (currentSelection.contains(category)) {
                  currentSelection.remove(category);
                } else {
                  currentSelection.add(category);
                }
                filterNotifier.state = currentFilterState.copyWith(selectedCategories: currentSelection);
              },
            ),
            _FilterSectionWidget(
              title: 'Subcategory',
              options: subcategoryOptions,
              selectedOptions: currentFilterState.selectedSubcategories,
              onSelected: (subcategory) {
                final currentSelection = List<String>.from(currentFilterState.selectedSubcategories);
                if (currentSelection.contains(subcategory)) {
                  currentSelection.remove(subcategory);
                } else {
                  currentSelection.add(subcategory);
                }
                filterNotifier.state = currentFilterState.copyWith(selectedSubcategories: currentSelection);
              },
            ),
            const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<SortOption>(
              value: currentFilterState.sortOption,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: SortOption.values.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option.displayName), // Uses the extension
                );
              }).toList(),
              onChanged: (newSortOption) {
                if (newSortOption != null) {
                  filterNotifier.state = currentFilterState.copyWith(sortOption: newSortOption);
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSectionWidget extends StatelessWidget {
  const _FilterSectionWidget({
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final List<String> selectedOptions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: options.map((option) {
              final isSelected = selectedOptions.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (_) => onSelected(option),
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// --- DELETED ---
// The old, duplicate enum SortOption that was here has been removed.
// The SortOptionExtension at the top of the file correctly handles this now.