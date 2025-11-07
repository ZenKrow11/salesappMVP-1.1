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

// --- Providers are unchanged ---

final _localFilterStateProvider = StateProvider.autoDispose<FilterState>((ref) {
  return ref.watch(homePageFilterStateProvider);
});

final _tappedStoresProvider = StateProvider.autoDispose<Set<String>>((ref) {
  return ref.watch(homePageFilterStateProvider).selectedStores.toSet();
});

final _isIncludeModeProvider = StateProvider.autoDispose<bool>((ref) => true);


class FilterBottomSheet extends ConsumerWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;

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
                    // ... (TabBarView children are unchanged)
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
                    CategoriesFilterTab(
                      selectedCategories: ref.watch(_localFilterStateProvider).selectedCategories,
                      onToggleCategory: (category) {
                        final current = ref.read(_localFilterStateProvider).selectedCategories.toSet();
                        current.contains(category) ? current.remove(category) : current.add(category);

                        ref.read(_localFilterStateProvider.notifier).update((state) =>
                            state.copyWith(
                              selectedCategories: current.toList(),
                              selectedSubcategories: [],
                            ));
                      },
                    ),
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
                  ref.read(homePageFilterStateProvider.notifier).update((state) => state.copyWith(
                    selectedStores: [],
                    selectedCategories: [],
                    selectedSubcategories: [],
                  ));

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

  // --- Other methods are unchanged ---

  void _toggleSetOption(WidgetRef ref, AutoDisposeStateProvider<Set<String>> provider, String option) {
    final currentSet = ref.read(provider);
    if (currentSet.contains(option)) {
      ref.read(provider.notifier).state = Set.from(currentSet)..remove(option);
    } else {
      ref.read(provider.notifier).state = Set.from(currentSet)..add(option);
    }
  }

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

    ref.read(homePageFilterStateProvider.notifier).state = finalState;
    Navigator.pop(context);
  }

  Widget _buildHeader(BuildContext context, AppThemeData theme, AppLocalizations l10n) {
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

  // --- THIS IS THE FIX ---
  Widget _buildTabBar(AppThemeData theme, AppLocalizations l10n) {
    return TabBar(
      isScrollable: true,
      // Add this line to align the tabs to the left
      tabAlignment: TabAlignment.start,
      labelColor: theme.secondary,
      unselectedLabelColor: theme.inactive,
      indicatorColor: theme.secondary,
      dividerColor: Colors.transparent,
      labelPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      tabs: [
        Tab(text: l10n.stores),
        Tab(text: l10n.categories),
        Tab(text: l10n.subcategories),
      ],
    );
  }
}