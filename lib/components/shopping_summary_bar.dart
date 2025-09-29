// lib/components/shopping_summary_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/widgets/item_count_widget.dart';

class ShoppingSummaryBar extends ConsumerWidget {
  final List<Product> products;

  const ShoppingSummaryBar({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    final double totalCost = products.fold(0, (sum, item) => sum + item.currentPrice);
    final double totalSavings = products.fold(0, (sum, item) => sum + (item.normalPrice - item.currentPrice));

    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
    final itemLimit = isPremium ? 60 : 30;

    return Container(
      // ===== FIX #3: Reduce vertical padding =====
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Adjusted to 8 for better balance, 2 was very tight
      decoration: BoxDecoration(
        color: theme.pageBackground,
        border: Border(
          top: BorderSide(color: theme.background, width: 1.0),
        ),
      ),
      // ===== FIX #2: Use spaceBetween for even distribution =====
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns the top of each column
        children: [
          // ===== FIX #1: Added a new helper for the item count with a title =====
          _buildItemCountSummary(products.length, itemLimit),

          _buildSummaryItem(
            'Saved',
            '${totalSavings.toStringAsFixed(2)} Fr.',
            theme.savingsColor,
            CrossAxisAlignment.center, // Center-align the middle element
          ),

          _buildSummaryItem(
            'Total',
            '${totalCost.toStringAsFixed(2)} Fr.',
            theme.secondary,
            CrossAxisAlignment.end, // Right-align the last element
          ),
        ],
      ),
    );
  }

  // ===== NEW HELPER WIDGET =====
  // This gives the item count a title, consistent with the other summary items.
  Widget _buildItemCountSummary(int filtered, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Left-align this block
      children: [
        Text(
          'Items',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        ItemCountWidget(
          filtered: filtered,
          total: total,
          showBackground: false,
        ),
      ],
    );
  }

  // --- MODIFIED HELPER WIDGET ---
  // Added an alignment parameter for more flexibility
  Widget _buildSummaryItem(String label, String value, Color valueColor, CrossAxisAlignment alignment) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}