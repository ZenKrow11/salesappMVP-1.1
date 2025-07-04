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
  // Use a set to track which panels are expanded.
  final Set<Object> _expandedPanelKeys = {};

  // --- THE FIX ---
  // Define STABLE keys here, outside the build method.
  // These keys will persist across rebuilds.
  final _categoryPanelKey = Object();
  final _subcategoryPanelKey = Object();
  final _sortPanelKey = Object();
  // --- END OF FIX ---

  void _handleExpansion(bool isExpanded, Object panelKey) {
    setState(() {
      if (isExpanded) {
        // If another panel is already expanded, close it first.
        // This ensures only one panel can be open at a time.
        if (_expandedPanelKeys.isNotEmpty && !_expandedPanelKeys.contains(panelKey)) {
          _expandedPanelKeys.clear();
        }
        _expandedPanelKeys.add(panelKey);
      } else {
        _expandedPanelKeys.remove(panelKey);
      }
    });
  }

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
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildFilterList()),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Filter and Sort', style: TextStyle(fontSize: 22,
              color: AppColors.secondary,
              fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.accent,
                size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterList() {
    final storeOptions = ref.watch(storeOptionsProvider);
    final categoryOptions = ref.watch(categoryOptionsProvider);
    final subcategoryOptions = ref.watch(subcategoryOptionsProvider);
    final currentFilterState = ref.watch(filterStateProvider);
    final filterNotifier = ref.read(filterStateProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Store', style: TextStyle(fontSize: 18,
              color: AppColors.inactive,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _StoreLogoFilter(
            allStores: storeOptions,
            selectedStores: currentFilterState.selectedStores,
            onStoreToggled: (store) {
              final newStores = _toggleListOption(currentFilterState.selectedStores, store);
              filterNotifier.state = currentFilterState.copyWith(
                selectedStores: newStores,
                selectedCategories: [],
                selectedSubcategories: [],
              );
            },
          ),
          const SizedBox(height: 24),

          // Pass the STABLE key to the builder method.
          _buildMultiSelectExpansionTile(
            key: _categoryPanelKey,
            title: 'Category',
            options: categoryOptions,
            selectedOptions: currentFilterState.selectedCategories,
            onOptionToggled: (category) {
              final newCategories = _toggleListOption(currentFilterState.selectedCategories, category);
              filterNotifier.state = currentFilterState.copyWith(
                selectedCategories: newCategories,
                selectedSubcategories: [],
              );
            },
          ),
          const SizedBox(height: 16),

          // Pass the STABLE key to the builder method.
          _buildMultiSelectExpansionTile(
            key: _subcategoryPanelKey,
            title: 'Subcategory',
            options: subcategoryOptions,
            selectedOptions: currentFilterState.selectedSubcategories,
            onOptionToggled: (subcategory) {
              final newSubcategories = _toggleListOption(currentFilterState.selectedSubcategories, subcategory);
              filterNotifier.state = currentFilterState.copyWith(selectedSubcategories: newSubcategories);
            },
          ),
          const SizedBox(height: 16),

          // Pass the STABLE key to the builder method.
          _buildSortExpansionTile(
            key: _sortPanelKey,
            currentSortOption: currentFilterState.sortOption,
            onSortChanged: (newSortOption) {
              if (newSortOption != null) {
                filterNotifier.state = currentFilterState.copyWith(sortOption: newSortOption);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final filterNotifier = ref.read(filterStateProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => filterNotifier.state = const FilterState(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.accent),
              ),
              child: const Text(
                style: TextStyle(color: AppColors.accent),
                  'Reset'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }

  // Modified to accept a key.
  Widget _buildMultiSelectExpansionTile({
    required Object key,
    required String title,
    required List<String> options,
    required List<String> selectedOptions,
    required ValueChanged<String> onOptionToggled,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.inactive,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey(key),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        initiallyExpanded: _expandedPanelKeys.contains(key),
        onExpansionChanged: (isExpanding) => _handleExpansion(isExpanding, key),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          const Divider(height: 1, indent: 16, endIndent: 16),
          if (options.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No options available.\nTry selecting a parent filter first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inactive),
              ),
            )
          else
            SizedBox(
              height: options.length > 5 ? 240 : null, // Constrain height if list is long
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = selectedOptions.contains(option);
                  return CheckboxListTile(
                    title: Text(option),
                    value: isSelected,
                    onChanged: (_) => onOptionToggled(option),
                    activeColor: AppColors.primary,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.trailing,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Modified to accept a key.
  Widget _buildSortExpansionTile({
    required Object key,
    required SortOption currentSortOption,
    required ValueChanged<SortOption?> onSortChanged,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.inactive,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey(key),
        title: Row(
          children: [
            const Text('Sort By:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentSortOption.displayName,
                style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        initiallyExpanded: _expandedPanelKeys.contains(key),
        onExpansionChanged: (isExpanding) => _handleExpansion(isExpanding, key),
        children: SortOption.values.map((option) {
          return RadioListTile<SortOption>(
            title: Text(option.displayName),
            value: option,
            groupValue: currentSortOption,
            onChanged: onSortChanged,
            activeColor: AppColors.primary,
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}

// Store logo filter - unchanged
class _StoreLogoFilter extends StatelessWidget {
  final List<String> allStores;
  final List<String> selectedStores;
  final ValueChanged<String> onStoreToggled;

  const _StoreLogoFilter({ required this.allStores, required this.selectedStores, required this.onStoreToggled });

  @override
  Widget build(BuildContext context) {
    if (allStores.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Loading stores...", style: TextStyle(color: Colors.grey)),
      ));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inactive,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        alignment: WrapAlignment.center,
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
                    color: AppColors.inactive,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.white,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 5, spreadRadius: 1)]
                        : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(1, 1))],
                  ),
                  child: StoreLogo(storeName: store, height: 32),
                ),
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_circle, color: AppColors.inactive, size: 28),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}