// lib/components/category_chip.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- ADDED IMPORT
import 'package:flutter_svg/flutter_svg.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import 'package:sales_app_mvp/models/category_style.dart';
import 'package:sales_app_mvp/services/category_service.dart';

class CategoryChip extends ConsumerWidget { // <-- CHANGED TO ConsumerWidget
  final String categoryName;

  const CategoryChip({
    super.key,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) { // <-- ADDED WidgetRef
    if (categoryName.isEmpty) {
      return const SizedBox.shrink();
    }

    // 2. GET THE LOCALIZATIONS OBJECT
    final l10n = AppLocalizations.of(context)!;

    // The logic here remains the same, but 'categoryName' is now a key.
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
              // 3. TRANSLATE THE KEY USING THE SERVICE
              CategoryService.getLocalizedCategoryName(categoryName, l10n),
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