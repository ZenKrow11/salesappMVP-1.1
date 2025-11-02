// C:\Users\patri\AndroidStudioProjects\salesappMVP-1.2\lib\components\categories_filter_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';

// 1. ADD THE REQUIRED IMPORTS for localization and your service.
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/services/category_service.dart';

class CategoriesFilterTab extends ConsumerWidget {
  final List<String> selectedCategories;
  final void Function(String) onToggleCategory;

  const CategoriesFilterTab({
    super.key,
    required this.selectedCategories,
    required this.onToggleCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final categoriesForFilterGrid = allCategories
        .where((cat) => cat.firestoreName != 'custom')
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3 / 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      // Use the new filtered list for the item count and builder
      itemCount: categoriesForFilterGrid.length,
      itemBuilder: (context, index) {
        // Get the category from the new filtered list
        final mainCategory = categoriesForFilterGrid[index];
        final isSelected =
        selectedCategories.contains(mainCategory.firestoreName);

        final localizedName = CategoryService.getLocalizedCategoryName(
          mainCategory.firestoreName,
          l10n,
        );
        // ========================================================================

        return _buildCategoryChip(
          ref,
          name: localizedName, // Pass the translated name to the chip.
          iconAssetPath: mainCategory.style.iconAssetPath,
          color: mainCategory.style.color,
          isSelected: isSelected,
          onTap: () => onToggleCategory(mainCategory.firestoreName),
        );
      },
    );
  }

  Widget _buildCategoryChip(
      WidgetRef ref, {
        required String name,
        required String iconAssetPath,
        required Color color,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    final theme = ref.watch(themeProvider);
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
}