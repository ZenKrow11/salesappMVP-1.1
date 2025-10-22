// lib/components/filter_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// --- Providers for the local "draft" state of the filter sheet ---

/// Holds the temporary filter state while the user is making changes.
final _localFilterStateProvider = StateProvider.autoDispose<FilterState>((ref) {
  // Initialize with the current global filter state.
  return ref.watch(filterStateProvider);
});

/// Manages the temporary set of stores tapped by the user.
final _tappedStoresProvider = StateProvider.autoDispose<Set<String>>((ref) {
  // Initialize with the current global selection.
  return ref.watch(filterStateProvider).selectedStores.toSet();
});

/// Manages the include/exclude toggle for the stores tab.
final _isIncludeModeProvider = StateProvider.autoDispose<bool>((ref) => true);


// --- The Refactored Widget ---

class FilterBottomSheet extends ConsumerWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;

    // The subcategory color map can be a simple final variable.
    final subCategoryColorMap = {
      for (var mainCat in allCategories)
        for (var subCat in mainCat.subcategories) subCat.name: mainCat.style.color
    };

    return DefaultTabController(
      length: 3,
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Column(
            children: [
              _buildHeader(context, theme, l10n),
              _buildTabBar(theme, l10n),
              Expanded(
                child: TabBarView(
                  children: [
                    // Stores Tab
                    StoresFilterTab(
                      isIncludeMode: ref.watch(_isIncludeModeProvider),
                      tappedStores: ref.watch(_tappedStoresProvider),
                      onToggleStore: (store) =>
                          _toggleSetOption(ref, _tappedStoresProvider, store),
                      onToggleMode: () {
                        ref.read(_isIncludeModeProvider.notifier).update((state) => !state);
                        ref.read(_tappedStoresProvider.notifier).state = {};
                      },
                    ),
                    // Categories Tab
                    CategoriesFilterTab(
                      selectedCategories: ref.watch(_localFilterStateProvider).selectedCategories,
                      onToggleCategory: (category) {
                        final current = ref.read(_localFilterStateProvider).selectedCategories.toSet();
                        current.contains(category) ? current.remove(category) : current.add(category);

                        // Update the local state provider
                        ref.read(_localFilterStateProvider.notifier).update((state) =>
                            state.copyWith(
                              selectedCategories: current.toList(),
                              selectedSubcategories: [], // Reset subcategories
                            ));
                      },
                    ),
                    // Subcategories Tab
                    SubcategoriesFilterTab(
                      localFilterState: ref.watch(_localFilterStateProvider),
                      subCategoryColorMap: subCategoryColorMap,
                      onToggleSubcategory: (subcategory) {
                        final current = ref.read(_localFilterStateProvider).selectedSubcategories.toSet();
                        current.contains(subcategory) ? current.remove(subcategory) : current.add(subcategory);

                        ref.read(_localFilterStateProvider.notifier).update((state) =>
                            state.copyWith(
                              selectedSubcategories: current.toList(),
                            ));
                      },
                    ),
                  ],
                ),
              ),
              FilterActionBar(
                onReset: () {
                  ref.invalidate(_localFilterStateProvider);
                  ref.invalidate(_tappedStoresProvider);
                  ref.invalidate(_isIncludeModeProvider);
                },
                onApply: () => _onApply(context, ref),
                isLoading: ref.watch(storeOptionsProvider).isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to toggle an item in a Set within a StateProvider.
  void _toggleSetOption(WidgetRef ref, AutoDisposeStateProvider<Set<String>> provider, String option) {
    // ================================================================
    final currentSet = ref.read(provider);
    if (currentSet.contains(option)) {
      ref.read(provider.notifier).state = Set.from(currentSet)..remove(option);
    } else {
      ref.read(provider.notifier).state = Set.from(currentSet)..add(option);
    }
  }

  /// Logic for applying the final filter to the global state.
  void _onApply(BuildContext context, WidgetRef ref) {
    final allStores = ref.read(storeOptionsProvider).value ?? [];
    final tappedStores = ref.read(_tappedStoresProvider);
    final isIncludeMode = ref.read(_isIncludeModeProvider);

    final finalSelectedStores = isIncludeMode
        ? tappedStores.toList()
        : Set<String>.from(allStores).difference(tappedStores).toList();

    var finalState = ref.read(_localFilterStateProvider).copyWith(
      selectedStores: finalSelectedStores,
    );

    ref.read(filterStateProvider.notifier).state = finalState;
    Navigator.pop(context);
  }

  Widget _buildHeader(BuildContext context, AppThemeData theme, AppLocalizations l10n) {
    // This widget's code remains the same
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
    // This widget's code remains the same
    return TabBar(
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