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
  // Use a single nullable object to track the expanded panel.
  // Using GlobalKey is not necessary here and this is simpler.
  Object? _expandedPanelKey;

  // Keys to uniquely identify each expansion tile.
  final _categoryKey = Object();
  final _subcategoryKey = Object();
  final _sortKey = Object();

  void _handleExpansion(bool isExpanded, Object panelKey) {
    setState(() {
      _expandedPanelKey = isExpanded ? panelKey : null;
    });
  }

  // Helper method to reduce code duplication for toggling items in a filter list.
  List<String> _toggleListOption(List<String> list, String option) {
    final newList = List<String>.from(list);
    if (newList.contains(option)) {
      newList.remove(option);
    } else {
      newList.add(option);
    }
    return newList;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Set max height to prevent the sheet from covering the whole screen.
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildFilterList(),
            ),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  /// Builds the header section with the title.
  Widget _buildHeader() {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text('Filter and Sort', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        Divider(height: 1, thickness: 1),
      ],
    );
  }

  /// Builds the main scrollable list of filter options.
  Widget _buildFilterList() {
    final storeOptions = ref.watch(storeOptionsProvider);
    final categoryOptions = ref.watch(categoryOptionsProvider);
    final subcategoryOptions = ref.watch(subcategoryOptionsProvider);
    final currentFilterState = ref.watch(filterStateProvider);
    final filterNotifier = ref.read(filterStateProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Store', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _StoreLogoFilter(
            allStores: storeOptions,
            selectedStores: currentFilterState.selectedStores,
            onStoreToggled: (store) {
              final newStores = _toggleListOption(currentFilterState.selectedStores, store);
              filterNotifier.state = currentFilterState.copyWith(selectedStores: newStores);
            },
          ),
          const SizedBox(height: 16),
          _buildFilterExpansionTile(
            key: _categoryKey,
            title: 'Category',
            options: categoryOptions,
            selectedOptions: currentFilterState.selectedCategories,
            onOptionToggled: (category) {
              final newCategories = _toggleListOption(currentFilterState.selectedCategories, category);
              // CRITICAL: When categories change, we must clear the subcategory selections
              // to prevent orphaned/invalid filter states.
              filterNotifier.state = currentFilterState.copyWith(
                selectedCategories: newCategories,
                selectedSubcategories: [],
              );
            },
          ),
          _buildFilterExpansionTile(
            key: _subcategoryKey,
            title: 'Subcategory',
            options: subcategoryOptions,
            selectedOptions: currentFilterState.selectedSubcategories,
            onOptionToggled: (subcategory) {
              final newSubcategories = _toggleListOption(currentFilterState.selectedSubcategories, subcategory);
              filterNotifier.state = currentFilterState.copyWith(selectedSubcategories: newSubcategories);
            },
          ),
          _buildSortExpansionTile(
            key: _sortKey,
            currentSortOption: currentFilterState.sortOption,
            onSortChanged: (newSortOption) {
              if (newSortOption != null) {
                filterNotifier.state = currentFilterState.copyWith(sortOption: newSortOption);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Builds the action bar with Reset and Apply buttons.
  Widget _buildActionBar() {
    final filterNotifier = ref.read(filterStateProvider.notifier);

    return Column(
      children: [
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                // ROBUSTNESS FIX: Use ElevatedButton instead of a styled OutlinedButton
                // to prevent the "Incorrect use of ParentDataWidget" crash.
                child: ElevatedButton(
                  onPressed: () => filterNotifier.state = const FilterState(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary, // Sets text color
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Apply', style: TextStyle(color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- WIDGET BUILDER HELPERS ---

  Widget _buildFilterExpansionTile({
    required Object key,
    required String title,
    required List<String> options,
    required List<String> selectedOptions,
    required ValueChanged<String> onOptionToggled,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();

    return ExpansionTile(
      key: ValueKey(key),
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
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(color: isSelected ? AppColors.primary : Colors.black87),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortExpansionTile({
    required Object key,
    required SortOption currentSortOption,
    required ValueChanged<SortOption?> onSortChanged,
  }) {
    return ExpansionTile(
      key: ValueKey(key),
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

// _StoreLogoFilter widget remains the same but is included for completeness.
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
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 5, spreadRadius: 1)]
                      : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(1, 1))],
                ),
                child: StoreLogo(storeName: store, height: 32),
              ),
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.6),
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