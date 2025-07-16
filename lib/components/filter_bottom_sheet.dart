import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/filter_options_provider.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late FilterState _localFilterState;

  final Set<Object> _expandedPanelKeys = {};
  final _storePanelKey = Object();
  final _categoryPanelKey = Object();
  final _subcategoryPanelKey = Object();

  @override
  void initState() {
    super.initState();
    _localFilterState = ref.read(filterStateProvider);
  }

  void _handleExpansion(bool isExpanded, Object panelKey) {
    setState(() {
      if (isExpanded) {
        _expandedPanelKeys.clear();
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
        color: AppColors.background,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
          const Text('Filter Products', style: TextStyle(fontSize: 22, color: AppColors.secondary, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.accent, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterList() {
    final storeOptions = ref.watch(storeOptionsProvider);
    final categoryOptions = ref.watch(categoryOptionsProviderFamily(_localFilterState));
    final subcategoryOptions = ref.watch(subcategoryOptionsProviderFamily(_localFilterState));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreExpansionTile(
            allStores: storeOptions,
            selectedStores: _localFilterState.selectedStores,
            onStoreToggled: (store) {
              setState(() {
                final newStores = _toggleListOption(_localFilterState.selectedStores, store);
                _localFilterState = _localFilterState.copyWith(
                  selectedStores: newStores,
                  selectedCategories: [],
                  selectedSubcategories: [],
                );
              });
            },
          ),
          const SizedBox(height: 16),
          _buildMultiSelectExpansionTile(
            key: _categoryPanelKey,
            title: 'Category',
            options: categoryOptions,
            selectedOptions: _localFilterState.selectedCategories,
            onOptionToggled: (category) {
              setState(() {
                final newCategories = _toggleListOption(_localFilterState.selectedCategories, category);
                _localFilterState = _localFilterState.copyWith(
                  selectedCategories: newCategories,
                  selectedSubcategories: [],
                );
              });
            },
          ),
          const SizedBox(height: 16),
          _buildMultiSelectExpansionTile(
            key: _subcategoryPanelKey,
            title: 'Subcategory',
            options: subcategoryOptions,
            selectedOptions: _localFilterState.selectedSubcategories,
            onOptionToggled: (subcategory) {
              setState(() {
                final newSubcategories = _toggleListOption(_localFilterState.selectedSubcategories, subcategory);
                _localFilterState = _localFilterState.copyWith(selectedSubcategories: newSubcategories);
              });
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
              onPressed: () => setState(() => _localFilterState = const FilterState()),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.accent),
              ),
              child: const Text('Reset', style: TextStyle(color: AppColors.accent)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                filterNotifier.state = _localFilterState;
                Navigator.pop(context);
              },
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

  // NOTE: The expansion tile builder methods (_buildStoreExpansionTile, _buildMultiSelectExpansionTile)
  // are identical to your previous version and are included below for completeness.

  Widget _buildStoreExpansionTile({
    required List<String> allStores,
    required List<String> selectedStores,
    required ValueChanged<String> onStoreToggled,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.inactive.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey(_storePanelKey),
        title: const Text('Store', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        initiallyExpanded: _expandedPanelKeys.contains(_storePanelKey),
        onExpansionChanged: (isExpanding) => _handleExpansion(isExpanding, _storePanelKey),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1, endIndent: 0, indent: 0),
          const SizedBox(height: 16),
          if (allStores.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Loading stores...", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Wrap(
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
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.secondary : Colors.white.withOpacity(0.5),
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppColors.secondary.withAlpha(75), blurRadius: 5, spreadRadius: 1)]
                              : [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 2, offset: const Offset(1, 1))],
                        ),
                        child: StoreLogo(storeName: store, height: 32),
                      ),
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withAlpha(150),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_circle, color: Colors.white, size: 28),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectExpansionTile({
    required Object key,
    required String title,
    required List<String> options,
    required List<String> selectedOptions,
    required ValueChanged<String> onOptionToggled,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.inactive.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey(key),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            SizedBox(
              height: options.length > 5 ? 240 : null,
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
                    activeColor: AppColors.secondary,
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
}