import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
// Corrected import path if it was different
import 'package:sales_app_mvp/providers/filter_options_provider.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet>
    with SingleTickerProviderStateMixin {
  // We keep a local copy of the filter state to allow the user to make
  // changes without affecting the main app state until they hit "APPLY".
  late FilterState _localFilterState;
  late TabController _tabController;
  Object? _expandedPanelKey;

  // These state variables are specific to the "Stores" tab UI
  bool _isIncludeMode = true;
  Set<String> _tappedStores = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Read the *initial* filter state from the global provider.
    final initialGlobalState = ref.read(filterStateProvider);
    _localFilterState = initialGlobalState;

    // We can't read the store options here anymore because they are async.
    // The logic for setting up the "exclude" mode needs to move into the build method
    // where we have access to the resolved `AsyncValue`.
    // We initialize `_tappedStores` with the current selection.
    _tappedStores = Set<String>.from(initialGlobalState.selectedStores);

    // The rest of the logic is moved to a more suitable place.
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- HELPER METHODS (UNCHANGED) ---
  void _handleExpansion(bool isExpanded, Object panelKey) {
    setState(() {
      _expandedPanelKey = isExpanded ? panelKey : null;
    });
  }

  void _toggleSetOption(Set<String> set, String option) {
    setState(() {
      if (set.contains(option)) {
        set.remove(option);
      } else {
        set.add(option);
      }
    });
  }
  // --- END HELPER METHODS ---

  @override
  Widget build(BuildContext context) {
    return Container(
      // The overall structure remains the same
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildStoresTab(), _buildCategoriesTab()],
            ),
          ),
          _buildActionBar(),
        ],
      ),
    );
  }

  // =======================================================================
  // === STORES TAB: Rebuilt to handle AsyncValue
  // =======================================================================
  Widget _buildStoresTab() {
    // 1. Watch the new FutureProvider
    final asyncStoreOptions = ref.watch(storeOptionsProvider);

    // 2. Use .when to handle loading/error/data states
    return asyncStoreOptions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (storeOptions) {
        // This block runs only when we have the list of stores.
        // It's now safe to perform logic that depends on this list.

        // This is the logic moved from initState. We run it here to
        // correctly determine the initial state of the include/exclude toggle
        // if this is the first time the data is loaded.
        // We check if the tapped stores are empty, which they will be on first load.
        if (_tappedStores.isEmpty && !_isIncludeMode) {
          final allStoresSet = Set<String>.from(storeOptions);
          final initialSelectedSet =
          Set<String>.from(_localFilterState.selectedStores);
          _tappedStores = allStoresSet.difference(initialSelectedSet);
        }

        final storeLogoWidgets = storeOptions.map((store) {
          final bool isSelected = _tappedStores.contains(store);
          return GestureDetector(
            onTap: () => _toggleSetOption(_tappedStores, store),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 56,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? (_isIncludeMode
                          ? AppColors.secondary
                          : AppColors.accent)
                          : Colors.white.withOpacity(0.5),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                          color: (_isIncludeMode
                              ? AppColors.secondary
                              : AppColors.accent)
                              .withAlpha(75),
                          blurRadius: 5,
                          spreadRadius: 1)
                    ]
                        : [
                      BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 2,
                          offset: const Offset(1, 1))
                    ],
                  ),
                  child: StoreLogo(storeName: store, height: 40),
                ),
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      width: 72,
                      height: 56,
                      decoration: BoxDecoration(
                        color: (_isIncludeMode
                            ? AppColors.secondary
                            : AppColors.accent)
                            .withAlpha(150),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isIncludeMode
                            ? Icons.check_circle
                            : Icons.do_not_disturb_on,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            alignment: WrapAlignment.center,
            children: [...storeLogoWidgets, _buildModeToggleTile()],
          ),
        );
      },
    );
  }

  // =======================================================================
  // === CATEGORIES TAB: Rebuilt to handle AsyncValue
  // =======================================================================
  Widget _buildCategoriesTab() {
    // Watch both providers. Riverpod will handle showing loading/error
    // if either of them is not ready.
    final asyncCategoryOptions = ref.watch(categoryOptionsProvider);
    final asyncSubcategoryOptions = ref.watch(subcategoryOptionsProvider);

    final categoryPanelKey = 'category';
    final subcategoryPanelKey = 'subcategory';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // CATEGORY TILE
        asyncCategoryOptions.when(
          loading: () => _buildLoadingExpansionTile('Category'),
          error: (e, s) => _buildErrorExpansionTile('Category'),
          data: (options) => _buildMultiSelectExpansionTile(
            key: ValueKey(categoryPanelKey),
            title: 'Category',
            options: options,
            selectedOptions: _localFilterState.selectedCategories,
            onOptionToggled: (category) {
              setState(() {
                final current = _localFilterState.selectedCategories.toSet();
                if (current.contains(category)) {
                  current.remove(category);
                } else {
                  current.add(category);
                }
                // When a category changes, clear subcategories
                _localFilterState = _localFilterState.copyWith(
                  selectedCategories: current.toList(),
                  selectedSubcategories: [],
                );
              });
            },
            onExpansionChanged: (isExpanding) =>
                _handleExpansion(isExpanding, categoryPanelKey),
            isExpanded: _expandedPanelKey == categoryPanelKey,
          ),
        ),
        const SizedBox(height: 12),
        // SUBCATEGORY TILE
        asyncSubcategoryOptions.when(
          loading: () => _buildLoadingExpansionTile('Subcategory'),
          error: (e, s) => _buildErrorExpansionTile('Subcategory'),
          data: (options) => _buildMultiSelectExpansionTile(
            key: ValueKey(subcategoryPanelKey),
            title: 'Subcategory',
            options: options,
            selectedOptions: _localFilterState.selectedSubcategories,
            onOptionToggled: (subcategory) {
              setState(() {
                final current = _localFilterState.selectedSubcategories.toSet();
                if (current.contains(subcategory)) {
                  current.remove(subcategory);
                } else {
                  current.add(subcategory);
                }
                _localFilterState = _localFilterState.copyWith(
                    selectedSubcategories: current.toList());
              });
            },
            onExpansionChanged: (isExpanding) =>
                _handleExpansion(isExpanding, subcategoryPanelKey),
            isExpanded: _expandedPanelKey == subcategoryPanelKey,
            emptyMessage: 'No subcategories available.\nSelect a category first.',
          ),
        ),
      ],
    );
  }

  // =======================================================================
  // === ACTION BAR: Rebuilt to handle AsyncValue
  // =======================================================================
  Widget _buildActionBar() {
    final filterNotifier = ref.read(filterStateProvider.notifier);
    // We need the resolved store options to calculate the "exclude" mode result
    final asyncStoreOptions = ref.watch(storeOptionsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.inactive),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() {
                _isIncludeMode = true;
                _tappedStores.clear();
                _localFilterState = const FilterState();
              }),
              child: const Text('RESET',
                  style: TextStyle(
                      color: AppColors.inactive, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              // Disable the button if the store options are still loading
              onPressed: asyncStoreOptions.isLoading
                  ? null
                  : () {
                List<String> finalSelectedStores;
                // Get the list of all stores from the resolved AsyncValue
                final allStores = asyncStoreOptions.value ?? [];

                if (_isIncludeMode) {
                  finalSelectedStores = _tappedStores.toList();
                } else {
                  final allStoresSet = Set<String>.from(allStores);
                  final finalStoresSet =
                  allStoresSet.difference(_tappedStores);
                  finalSelectedStores = finalStoresSet.toList();
                }

                // Update the local state with the final store selection
                _localFilterState = _localFilterState.copyWith(
                    selectedStores: finalSelectedStores);

                // Apply the final local state to the global provider
                filterNotifier.state = _localFilterState;
                Navigator.pop(context);
              },
              child: const Text('APPLY',
                  style: TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER WIDGETS (MOSTLY UNCHANGED OR NEW) ---

  Widget _buildModeToggleTile() {
    final IconData iconData =
    _isIncludeMode ? Icons.add_circle : Icons.remove_circle;
    // THIS IS THE LINE TO FIX:
    final Color iconColor =
    _isIncludeMode ? AppColors.secondary : AppColors.accent; // Corrected from _isInclude_mode

    return GestureDetector(
      onTap: () {
        setState(() {
          _isIncludeMode = !_isIncludeMode;
          _tappedStores.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor, width: 2.0),
          boxShadow: [
            BoxShadow(color: iconColor.withAlpha(75), blurRadius: 5, spreadRadius: 1)
          ],
        ),
        child: Center(child: Icon(iconData, color: iconColor, size: 36)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Filter Products',
              style: TextStyle(
                  fontSize: 20,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.accent, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.secondary,
      unselectedLabelColor: AppColors.inactive,
      indicatorColor: AppColors.secondary,
      dividerColor: Colors.transparent,
      tabs: const [
        Tab(text: 'Stores'),
        Tab(text: 'Categories'),
      ],
    );
  }

  // NEW helper for loading state
  Widget _buildLoadingExpansionTile(String title) {
    return Card(
      elevation: 0,
      color: AppColors.inactive.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        trailing: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  // NEW helper for error state
  Widget _buildErrorExpansionTile(String title) {
    return Card(
      elevation: 0,
      color: AppColors.accent.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text('Error loading $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.accent)),
        trailing: const Icon(Icons.error_outline, color: AppColors.accent),
      ),
    );
  }

  Widget _buildMultiSelectExpansionTile({
    required Key key,
    required String title,
    required List<String> options,
    required List<String> selectedOptions,
    required ValueChanged<String> onOptionToggled,
    required ValueChanged<bool> onExpansionChanged,
    required bool isExpanded,
    String emptyMessage = 'No options available.',
  }) {
    return Card(
      elevation: 0,
      color: isExpanded
          ? AppColors.inactive.withOpacity(0.15)
          : AppColors.inactive.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: key,
        title: Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        iconColor: AppColors.accent,
        collapsedIconColor: AppColors.inactive,
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.inactive),
          if (options.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inactive),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = selectedOptions.contains(option);
                  return CheckboxListTile(
                    title:
                    Text(option, style: const TextStyle(color: AppColors.textPrimary)),
                    value: isSelected,
                    onChanged: (_) => onOptionToggled(option),
                    activeColor: AppColors.secondary,
                    checkColor: AppColors.primary,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    side: const BorderSide(color: AppColors.inactive),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}