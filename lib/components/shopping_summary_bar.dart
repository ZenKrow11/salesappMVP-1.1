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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.pageBackground,
        border: Border(
          top: BorderSide(color: theme.background, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ItemCountWidget(
            filtered: products.length,
            total: itemLimit,
            // ===== FIX: Tell the widget NOT to show its background =====
            showBackground: false,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSummaryItem(
                  'Saved',
                  '${totalSavings.toStringAsFixed(2)} Fr.',
                  theme.savingsColor,
                ),
                const SizedBox(width: 24),
                _buildSummaryItem(
                  'Total',
                  '${totalCost.toStringAsFixed(2)} Fr.',
                  theme.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    // ... (this helper method remains unchanged)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
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