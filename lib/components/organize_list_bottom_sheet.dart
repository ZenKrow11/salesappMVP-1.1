// lib/components/organize_list_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/filter_action_bar.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_options_provider.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart'; // <-- IMPORT YOUR WIDGET

// Re-using the localization extension from your sort_bottom_sheet
import 'sort_bottom_sheet.dart' show SortOptionLocalization;

class OrganizeListBottomSheet extends ConsumerStatefulWidget {
  const OrganizeListBottomSheet({super.key});

  @override
  ConsumerState<OrganizeListBottomSheet> createState() =>
      _OrganizeListBottomSheetState();
}

class _OrganizeListBottomSheetState extends ConsumerState<OrganizeListBottomSheet>
    with SingleTickerProviderStateMixin {
  late FilterState _localFilterState;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Clone the global state to a local state for modification
    _localFilterState = ref.read(filterStateProvider);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    final asyncStoreOptions = ref.watch(storeOptionsProvider);
    final filterNotifier = ref.read(filterStateProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(theme, l10n),
            _buildTabBar(theme, l10n),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Stores Tab
                  asyncStoreOptions.when(
                    data: (stores) => _buildStoresTab(stores, theme),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  ),
                  // Categories Tab
                  _buildCategoriesTab(theme, l10n),
                  // Sort Tab
                  _buildSortTab(l10n, theme),
                ],
              ),
            ),
            FilterActionBar(
              onReset: () {
                setState(() {
                  _localFilterState = const FilterState();
                });
              },
              onApply: () {
                // Apply local changes to the global state provider
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
            l10n.organizeList,
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
        Tab(text: l10n.sortBy),
      ],
    );
  }

  Widget _buildStoresTab(List<String> stores, AppThemeData theme) {
    final selectedStores = _localFilterState.selectedStores.toSet();
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5, // Adjust aspect ratio for logos
      ),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        final isSelected = selectedStores.contains(store);
        return InkWell(
          onTap: () {
            final current = _localFilterState.selectedStores.toSet();
            if (current.contains(store)) {
              current.remove(store);
            } else {
              current.add(store);
            }
            setState(() {
              _localFilterState =
                  _localFilterState.copyWith(selectedStores: current.toList());
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: theme.secondary, width: 3)
                  : null,
            ),
            // --- FIX: USING YOUR StoreLogo WIDGET ---
            child: Center(child: StoreLogo(storeName: store, height: 40)),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab(AppThemeData theme, AppLocalizations l10n) {
    final selectedCategories = _localFilterState.selectedCategories.toSet();
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.5, // Wider aspect ratio for text
      ),
      itemCount: allCategories.length,
      itemBuilder: (context, index) {
        final category = allCategories[index];
        final isSelected = selectedCategories.contains(category.firestoreName);
        final style = CategoryService.getLocalizedStyleForGroupingName(category.firestoreName, l10n);

        return InkWell(
          onTap: () {
            final current = _localFilterState.selectedCategories.toSet();
            if (current.contains(category.firestoreName)) {
              current.remove(category.firestoreName);
            } else {
              current.add(category.firestoreName);
            }
            setState(() {
              _localFilterState = _localFilterState.copyWith(selectedCategories: current.toList());
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? style.color : theme.primary,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: theme.secondary, width: 2) : null,
            ),
            child: Center(
              child: Text(
                style.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.inactive,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortTab(AppLocalizations l10n, AppThemeData theme) {
    final relevantSortOptions = [
      SortOption.storeAlphabetical,
      SortOption.productAlphabetical,
      SortOption.priceLowToHigh,
      SortOption.priceHighToLow,
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: relevantSortOptions.map((option) {
        final isSelected = option == _localFilterState.sortOption;
        return Card(
          elevation: 0,
          color: isSelected ? theme.secondary : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.primary, width: 1.5),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(
              option.getLocalizedDisplayName(l10n),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.primary : theme.inactive,
              ),
            ),
            onTap: () {
              setState(() {
                _localFilterState = _localFilterState.copyWith(sortOption: option);
              });
            },
          ),
        );
      }).toList(),
    );
  }
}