import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/models/category_definitions.dart';

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
    return GridView.builder(
      // --- CHANGE: Slightly reduced vertical padding to give more room ---
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 3 / 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allCategories.length,
      itemBuilder: (context, index) {
        final mainCategory = allCategories[index];
        final isSelected =
        selectedCategories.contains(mainCategory.firestoreName);

        return _buildCategoryChip(
          ref,
          name: mainCategory.style.displayName,
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Adjusted padding
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
            // --- FIX: Replaced fixed-size SizedBox with Expanded ---
            // This makes the SVG icon flexible. It will now shrink to fit
            // the available space after the text has been laid out.
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