// lib/components/shopping_summary_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class ShoppingSummaryBar extends ConsumerWidget {
  final List<Product> products;

  const ShoppingSummaryBar({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    // Perform calculations
    final double totalCost = products.fold(0, (sum, item) => sum + item.currentPrice);
    final double totalSavings = products.fold(0, (sum, item) => sum + (item.normalPrice - item.currentPrice));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // Slightly adjusted padding
      decoration: BoxDecoration(
        // ===== CHANGE #1: Use a different color for distinction =====
        // This color matches the page's background, separating it from the
        // darker BottomNavigationBar.
        color: theme.pageBackground,
        border: Border(
          top: BorderSide(color: theme.background, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pushes items to the ends
        children: [
          // Savings
          _buildSummaryItem(
            'Saved',
            '${totalSavings.toStringAsFixed(2)} Fr.', // Note: Removed space for consistency
            theme.savingsColor,
          ),
          // Total Cost
          _buildSummaryItem(
            'Total',
            '${totalCost.toStringAsFixed(2)} Fr.',
            theme.secondary,
          ),
        ],
      ),
    );
  }

  // ===== CHANGE #2: Helper is now a Row to save vertical space =====
  // This new helper places the label and value on the same line.
  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Row(
      // This ensures perfect vertical alignment of text with different font sizes.
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$label: ', // Add the colon and space here
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14, // Slightly larger for better readability on one line
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}