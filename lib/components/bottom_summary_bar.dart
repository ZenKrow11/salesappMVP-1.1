// lib/components/bottom_summary_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class BottomSummaryBar extends ConsumerWidget {
  final List<Product> products;
  final int itemLimit = 30; // The item limit for free users.

  const BottomSummaryBar({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    // Perform calculations
    final double totalCost = products.fold(0, (sum, item) => sum + item.currentPrice);
    final double totalSavings = products.fold(0, (sum, item) => sum + (item.normalPrice - item.currentPrice));
    final int itemCount = products.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.background,
        // Add a subtle border on top for separation
        border: Border(
          top: BorderSide(color: theme.primary.withOpacity(0.5), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Item Count
          _buildInfoColumn(
            context,
            '${itemCount.toString()}/${itemLimit.toString()}',
            'Items',
            theme,
            isHighlighted: false,
          ),
          // Savings
          _buildInfoColumn(
            context,
            '- ${totalSavings.toStringAsFixed(2)} Fr.',
            'Saved',
            theme,
            isHighlighted: false,
          ),
          // Total Cost
          _buildInfoColumn(
            context,
            '${totalCost.toStringAsFixed(2)} Fr.',
            'Total',
            theme,
            isHighlighted: true, // Highlight the total cost
          ),
        ],
      ),
    );
  }

  // Helper widget to create a consistent text column
  Widget _buildInfoColumn(BuildContext context, String value, String label, AppThemeData theme, {required bool isHighlighted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min, // Important for the column to not take too much space
      children: [
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? theme.secondary : theme.inactive,
            fontSize: isHighlighted ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: theme.inactive.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}