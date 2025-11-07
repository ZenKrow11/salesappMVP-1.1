// lib/components/organize_list_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sales_app_mvp/components/filter_action_bar.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_options_provider.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/services/category_service.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';

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
    _localFilterState = ref.read(shoppingListPageFilterStateProvider);
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
    final filterNotifier =
    ref.read(shoppingListPageFilterStateProvider.notifier);

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
                  asyncStoreOptions.when(
                    data: (stores) => _buildStoresTab(stores, theme),
                    loading: () =>
                    const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  ),
                  _buildCategoriesTab(theme, l10n),
                  _buildSortTab(l10n, theme),
                ],
              ),
            ),
            FilterActionBar(
              onReset: () {
                setState(() {
                  _localFilterState =
                  const FilterState(sortOption: SortOption.storeAlphabetical);
                });
              },
              onApply: () {
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
      // --- THIS IS THE FIX ---
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      // ----------------------
      labelColor: theme.secondary,
      unselectedLabelColor: theme.inactive,
      indicatorColor: theme.secondary,
      dividerColor: Colors.transparent,
      // Add some padding for better spacing
      labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
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
        childAspectRatio: 1.5,
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
            child: Center(child: StoreLogo(storeName: store, height: 40)),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab(AppThemeData theme, AppLocalizations l10n) {
    final selectedCategories = _localFilterState.selectedCategories.toSet();
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3 / 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allCategories.length,
      itemBuilder: (context, index) {
        final category = allCategories[index];
        final isSelected = selectedCategories.contains(category.firestoreName);
        final style = CategoryService.getLocalizedStyleForGroupingName(
            category.firestoreName, l10n);

        return _buildCategoryChip(
          theme: theme,
          name: style.displayName,
          iconAssetPath: category.style.iconAssetPath,
          color: category.style.color,
          isSelected: isSelected,
          onTap: () {
            final current = _localFilterState.selectedCategories.toSet();
            if (current.contains(category.firestoreName)) {
              current.remove(category.firestoreName);
            } else {
              current.add(category.firestoreName);
            }
            setState(() {
              _localFilterState = _localFilterState.copyWith(
                  selectedCategories: current.toList());
            });
          },
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required AppThemeData theme,
    required String name,
    required String iconAssetPath,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final contentColor = Colors.white;
    final selectionColor = theme.secondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? selectionColor : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SvgPicture.asset(
                iconAssetPath,
                colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                color: contentColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- CHANGE: This entire method has been updated to use the new style ---
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
          // Use theme.primary for inactive background color
          color: isSelected ? theme.secondary : theme.primary,
          // Remove the border for a cleaner look
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
                _localFilterState =
                    _localFilterState.copyWith(sortOption: option);
              });
            },
          ),
        );
      }).toList(),
    );
  }
}