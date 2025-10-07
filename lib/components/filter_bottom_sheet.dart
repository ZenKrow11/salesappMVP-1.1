// lib/components/filter_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// (imports are the same)
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/providers/filter_options_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'stores_filter_tab.dart';
import 'categories_filter_tab.dart';
import 'subcategories_filter_tab.dart';
import 'filter_action_bar.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet>
    with SingleTickerProviderStateMixin {
  // ... (initState, dispose, and other methods are the same)
  late FilterState _localFilterState;
  late TabController _tabController;
  bool _isIncludeMode = true;
  Set<String> _tappedStores = {};
  final Map<String, Color> _subCategoryColorMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final initialGlobalState = ref.read(filterStateProvider);
    _localFilterState = initialGlobalState;
    _tappedStores = Set<String>.from(initialGlobalState.selectedStores);
    for (var mainCat in allCategories) {
      for (var subCat in mainCat.subcategories) {
        _subCategoryColorMap[subCat.name] = mainCat.style.color;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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


  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final asyncStoreOptions = ref.watch(storeOptionsProvider);
    final filterNotifier = ref.read(filterStateProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      // --- THIS IS THE FIX ---
      // Wrap the main Column in a SafeArea to prevent overlapping
      // with the system navigation bar at the bottom.
      child: SafeArea(
        top: false, // Not needed for a bottom sheet
        bottom: true,
        child: Column(
          children: [
            _buildHeader(theme, l10n),
            _buildTabBar(theme, l10n),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  StoresFilterTab(
                    isIncludeMode: _isIncludeMode,
                    tappedStores: _tappedStores,
                    onToggleStore: (store) => _toggleSetOption(_tappedStores, store),
                    onToggleMode: () => setState(() {
                      _isIncludeMode = !_isIncludeMode;
                      _tappedStores.clear();
                    }),
                  ),
                  CategoriesFilterTab(
                    selectedCategories: _localFilterState.selectedCategories,
                    onToggleCategory: (category) {
                      setState(() {
                        final current = _localFilterState.selectedCategories.toSet();
                        if (current.contains(category)) {
                          current.remove(category);
                        } else {
                          current.add(category);
                        }
                        _localFilterState = _localFilterState.copyWith(
                          selectedCategories: current.toList(),
                          selectedSubcategories: [],
                        );
                      });
                    },
                  ),
                  SubcategoriesFilterTab(
                    localFilterState: _localFilterState,
                    subCategoryColorMap: _subCategoryColorMap,
                    onToggleSubcategory: (subcategory) {
                      setState(() {
                        final current = _localFilterState.selectedSubcategories.toSet();
                        if (current.contains(subcategory)) {
                          current.remove(subcategory);
                        } else {
                          current.add(subcategory);
                        }
                        _localFilterState = _localFilterState.copyWith(
                          selectedSubcategories: current.toList(),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            FilterActionBar(
              onReset: () => setState(() {
                _isIncludeMode = true;
                _tappedStores.clear();
                _localFilterState = const FilterState();
              }),
              onApply: () {
                final allStores = asyncStoreOptions.value ?? [];
                final finalSelectedStores = _isIncludeMode
                    ? _tappedStores.toList()
                    : Set<String>.from(allStores)
                    .difference(_tappedStores)
                    .toList();

                _localFilterState = _localFilterState.copyWith(
                  selectedStores: finalSelectedStores,
                );

                filterNotifier.state = _localFilterState;
                Navigator.pop(context);
              },
              isLoading: asyncStoreOptions.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.filterProducts,
            style: TextStyle(
              fontSize: 20,
              color: theme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.accent, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppThemeData theme, AppLocalizations l10n) {
    return TabBar(
      controller: _tabController,
      labelColor: theme.secondary,
      unselectedLabelColor: theme.inactive,
      indicatorColor: theme.secondary,
      dividerColor: Colors.transparent,
      tabs: [
        Tab(text: l10n.stores),
        Tab(text: l10n.categories),
        Tab(text: l10n.subcategories),
      ],
    );
  }
}