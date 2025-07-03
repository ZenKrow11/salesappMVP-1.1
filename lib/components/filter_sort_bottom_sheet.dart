import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/filter_options_provider.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

// Extension remains the same.
extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.storeAlphabetical: return 'Store: A-Z';
      case SortOption.productAlphabetical: return 'Products A-Z';
      case SortOption.discountHighToLow: return 'Discount: High to Low';
      case SortOption.discountLowToHigh: return 'Discount: Low to High';
      case SortOption.priceLowToHigh: return 'Price: Low to High';
      case SortOption.priceHighToLow: return 'Price: High to Low';
    }
  }
}

class FilterSortBottomSheet extends ConsumerStatefulWidget {
  const FilterSortBottomSheet({super.key});

  @override
  ConsumerState<FilterSortBottomSheet> createState() => _FilterSortBottomSheetState();
}

class _FilterSortBottomSheetState extends ConsumerState<FilterSortBottomSheet> {
  Object? _expandedPanelKey;

  void _handleExpansion(bool isExpanded, Object panelKey) {
    setState(() {
      if (isExpanded) {
        _expandedPanelKey = panelKey;
      } else if (_expandedPanelKey == panelKey) {
        _expandedPanelKey = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final storeOptions = ref.watch(storeOptionsProvider);
    final categoryOptions = ref.watch(categoryOptionsProvider);
    final subcategoryOptions = ref.watch(subcategoryOptionsProvider);
    final currentFilterState = ref.watch(filterStateProvider);
    final filterNotifier = ref.read(filterStateProvider.notifier);

    final categoryKey = GlobalKey();
    final subcategoryKey = GlobalKey();
    final sortKey = GlobalKey();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text('Filter and Sort', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Store', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // Using the newly refactored Store Logo filter
                    _StoreLogoFilter(
                      allStores: storeOptions,
                      selectedStores: currentFilterState.selectedStores,
                      onStoreToggled: (store) {
                        final currentSelection = List<String>.from(currentFilterState.selectedStores);
                        if (currentSelection.contains(store)) {
                          currentSelection.remove(store);
                        } else {
                          currentSelection.add(store);
                        }
                        filterNotifier.state = currentFilterState.copyWith(selectedStores: currentSelection);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFilterExpansionTile(
                      key: categoryKey,
                      title: 'Category',
                      options: categoryOptions,
                      selectedOptions: currentFilterState.selectedCategories,
                      onOptionToggled: (category) {
                        final currentSelection = List<String>.from(currentFilterState.selectedCategories);
                        if (currentSelection.contains(category)) {
                          currentSelection.remove(category);
                        } else {
                          currentSelection.add(category);
                        }
                        filterNotifier.state = currentFilterState.copyWith(selectedCategories: currentSelection);
                      },
                    ),
                    _buildFilterExpansionTile(
                      key: subcategoryKey,
                      title: 'Subcategory',
                      options: subcategoryOptions,
                      selectedOptions: currentFilterState.selectedSubcategories,
                      onOptionToggled: (subcategory) {
                        final currentSelection = List<String>.from(currentFilterState.selectedSubcategories);
                        if (currentSelection.contains(subcategory)) {
                          currentSelection.remove(subcategory);
                        } else {
                          currentSelection.add(subcategory);
                        }
                        filterNotifier.state = currentFilterState.copyWith(selectedSubcategories: currentSelection);
                      },
                    ),
                    _buildSortExpansionTile(
                      key: sortKey,
                      currentSortOption: currentFilterState.sortOption,
                      onSortChanged: (newSortOption) {
                        if (newSortOption != null) {
                          filterNotifier.state = currentFilterState.copyWith(sortOption: newSortOption);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => filterNotifier.state = const FilterState(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.primary, // Use backgroundColor for OutlinedButton
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary, // Use backgroundColor for ElevatedButton
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Apply'
                          , style: TextStyle(color: AppColors.primary),
                          )
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterExpansionTile({
    required Key key,
    required String title,
    required List<String> options,
    required List<String> selectedOptions,
    required ValueChanged<String> onOptionToggled,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      key: key,
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      initiallyExpanded: _expandedPanelKey == key,
      onExpansionChanged: (isExpanding) => _handleExpansion(isExpanding, key),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 16),
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onOptionToggled(option),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(color: isSelected ? AppColors.primary : Colors.black87),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortExpansionTile({
    required Key key,
    required SortOption currentSortOption,
    required ValueChanged<SortOption?> onSortChanged,
  }) {
    return ExpansionTile(
      key: key,
      title: const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      initiallyExpanded: _expandedPanelKey == key,
      onExpansionChanged: (isExpanding) => _handleExpansion(isExpanding, key),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 16),
      children: SortOption.values.map((option) {
        return RadioListTile<SortOption>(
          title: Text(option.displayName),
          value: option,
          groupValue: currentSortOption,
          onChanged: onSortChanged,
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
}

// --- NEW WIDGET with Checkmark overlay for store logos ---
class _StoreLogoFilter extends StatelessWidget {
  final List<String> allStores;
  final List<String> selectedStores;
  final ValueChanged<String> onStoreToggled;

  const _StoreLogoFilter({
    required this.allStores,
    required this.selectedStores,
    required this.onStoreToggled,
  });

  @override
  Widget build(BuildContext context) {
    if (allStores.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Loading stores...", style: TextStyle(color: Colors.grey)),
      ));
    }

    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: allStores.map((store) {
        final isSelected = selectedStores.contains(store);
        return GestureDetector(
          onTap: () => onStoreToggled(store),
          child: Stack(
            alignment: Alignment.center, // Center the overlay and checkmark
            children: [
              // The main logo container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.white,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 5, spreadRadius: 1)]
                      : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(1, 1))],
                ),
                child: StoreLogo(storeName: store, height: 32),
              ),
              // The checkmark and overlay when selected
              if (isSelected)
                Positioned.fill( // Fills the entire space of the Stack
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.6), // Semi-transparent overlay
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.white, size: 28),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}