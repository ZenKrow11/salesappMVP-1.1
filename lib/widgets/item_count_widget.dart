import 'package:flutter/material.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class ItemCountWidget extends StatelessWidget {
  final int filtered;
  final int total;

  const ItemCountWidget({
    super.key,
    required this.filtered,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    // A small container to sit inside the search bar's suffix area.
    // We add padding here to control its size.
    return Padding(
      padding: const EdgeInsets.only(right: 8.0), // Padding from the edge of the search bar
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          // Using a slightly different color to distinguish from the search bar itself
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          '$filtered/$total',
          style: const TextStyle(
            color: AppColors.inactive,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}