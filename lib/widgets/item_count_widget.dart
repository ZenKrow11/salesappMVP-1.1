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
    // REMOVED: The outer Padding widget.
    return Container(
      // The padding is now inside the container
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: AppColors.primary, // Or maybe a slightly different color
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
    );
  }
}