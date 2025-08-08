// lib/components/category_chip.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sales_app_mvp/models/category_style.dart';
import 'package:sales_app_mvp/services/category_service.dart';

class CategoryChip extends StatelessWidget {
  final String categoryName;

  const CategoryChip({
    super.key,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryName.isEmpty) {
      return const SizedBox.shrink();
    }
    final CategoryStyle style = CategoryService.getStyleForCategory(categoryName);
    final bool isSub = CategoryService.isSubCategory(categoryName);
    final Color chipColor = isSub ? style.color.withAlpha(200) : style.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor,
        border: Border.all(color: chipColor, width: 1.5),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            style.iconAssetPath,
            height: 16,
            width: 16,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              categoryName,
              style: const TextStyle(
                fontSize: 12,
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