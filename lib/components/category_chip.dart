// lib/components/category_chip.dart

import 'package:flutter/material.dart';
import 'package:sales_app_mvp/services/category_service.dart';

class CategoryChip extends StatelessWidget {
  final String categoryName;

  const CategoryChip({
    super.key,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    // If the category name is empty, don't build anything.
    if (categoryName.isEmpty) {
      return const SizedBox.shrink();
    }

    // 1. Get the base style from the service. This will be the parent style.
    final style = CategoryService.getStyleForCategory(categoryName);

    // 2. Ask the service if this is a subcategory.
    final bool isSub = CategoryService.isSubCategory(categoryName);

    // 3. Define colors based on whether it's a subcategory or not.
    //    - Subcategories will have a less intense color.
    //    - We use `withOpacity` for a consistent shading effect.
    final Color chipColor = isSub ? style.color.withValues(alpha: 0.7) : style.color;
    final Color backgroundColor = chipColor; // Use the chip color for a solid background.

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        // The border takes on the main or shaded color.
        border: Border.all(color: chipColor, width: 1.5),
        borderRadius: BorderRadius.circular(5.0), // A rounded, "pill" shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Keep the chip tight around its content
        children: [
          Icon(
            style.icon,
            size: 16,
            color: Colors.white, // Icon is white.
          ),
          const SizedBox(width: 6),
          Flexible( // Prevents long names from causing a layout overflow
            child: Text(
              categoryName,
              style: TextStyle(
                fontSize: 12, // Text is white.
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}