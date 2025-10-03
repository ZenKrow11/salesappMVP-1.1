// lib/components/subcategories_filter_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class SubcategoriesFilterTab extends ConsumerWidget {
  final FilterState localFilterState;
  final Map<String, Color> subCategoryColorMap;
  final void Function(String subcategory) onToggleSubcategory;

  const SubcategoriesFilterTab({
    super.key,
    required this.localFilterState,
    required this.subCategoryColorMap,
    required this.onToggleSubcategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    // 2. GET THE LOCALIZATIONS OBJECT
    final l10n = AppLocalizations.of(context)!;

    if (localFilterState.selectedCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // 3. REPLACE HARDCODED TEXT
          child: Text(
            l10n.pleaseSelectCategoryFirst,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.inactive, fontSize: 16),
          ),
        ),
      );
    }

    final availableSubcategories = <SubCategory>[];
    for (var mainCategory in allCategories) {
      if (localFilterState.selectedCategories
          .contains(mainCategory.firestoreName)) {
        availableSubcategories.addAll(mainCategory.subcategories);
      }
    }

    final uniqueNames = <String>{};
    final uniqueSubcategories =
    availableSubcategories.where((s) => uniqueNames.add(s.name)).toList();

    if (uniqueSubcategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            l10n.noSubcategoriesAvailable,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.inactive, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: uniqueSubcategories.length,
      itemBuilder: (context, index) {
        final sub = uniqueSubcategories[index];
        final isSelected =
        localFilterState.selectedSubcategories.contains(sub.name);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onToggleSubcategory(sub.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? theme.secondary : Colors.transparent,
                  width: 2.0,
                ),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    sub.iconAssetPath,
                    colorFilter: ColorFilter.mode(
                        theme.secondary, BlendMode.srcIn),
                    height: 32,
                    width: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    // NOTE: This text is correct as is. 'sub.name' is data
                    // that should be localized at its source (CategoryService).
                    child: Text(
                      sub.name,
                      style: TextStyle(
                        color: theme.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: isSelected ? theme.secondary : theme.inactive,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}