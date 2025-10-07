// lib/components/category_chip.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/category_style.dart';
import 'package:sales_app_mvp/services/category_service.dart';

class CategoryChip extends StatelessWidget {
  final String categoryKey; // Renamed for clarity

  const CategoryChip({
    super.key,
    required this.categoryKey,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryKey.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final CategoryStyle style = CategoryService.getStyleForCategory(categoryKey);
    final bool isSub = CategoryService.isSubCategory(categoryKey);
    final Color chipColor = isSub ? style.color.withAlpha(200) : style.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor,
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
              // The chip now handles its own translation correctly
              CategoryService.getLocalizedCategoryName(categoryKey, l10n),
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