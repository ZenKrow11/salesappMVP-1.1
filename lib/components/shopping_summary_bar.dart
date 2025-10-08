// lib/components/shopping_summary_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/shopping_mode_screen.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/widgets/item_count_widget.dart';

// --- ADD THIS IMPORT FOR THE CUSTOM PAGE ROUTE ---
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';

class ShoppingSummaryBar extends ConsumerWidget {
  final List<Product> products;

  const ShoppingSummaryBar({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    // 2. GET THE LOCALIZATIONS OBJECT
    final l10n = AppLocalizations.of(context)!;

    final double totalCost = products.fold(0, (sum, item) => sum + item.currentPrice);
    final double totalSavings = products.fold(0, (sum, item) => sum + (item.normalPrice - item.currentPrice));

    final isPremium = ref.watch(userProfileProvider).value?.isPremium ?? false;
    final itemLimit = isPremium ? 60 : 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.pageBackground,
        border: Border(
          top: BorderSide(color: theme.background, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3. PASS l10n TO HELPER METHODS
              _buildItemCountSummary(products.length, itemLimit, l10n),
              const SizedBox(width: 20),
              // 4. REPLACE HARDCODED TEXT
              _buildSummaryItem(
                l10n.saved,
                '${totalSavings.toStringAsFixed(2)} ${l10n.currencyFrancs}',
                theme.savingsColor,
                CrossAxisAlignment.start,
              ),
              const SizedBox(width: 20),
              _buildSummaryItem(
                l10n.total,
                '${totalCost.toStringAsFixed(2)} ${l10n.currencyFrancs}',
                theme.secondary,
                CrossAxisAlignment.start,
              ),
            ],
          ),

          FilledButton.icon(
            onPressed: () {
              // --- THIS IS THE CHANGE ---
              // Replace MaterialPageRoute with SlideUpPageRoute
              Navigator.push(
                context,
                SlideUpPageRoute(page: const ShoppingModeScreen()),
              );
            },
            icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 20),
            label: Text(l10n.shop),
            style: FilledButton.styleFrom(
              backgroundColor: theme.secondary,
              foregroundColor: theme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // UPDATE SIGNATURE TO ACCEPT l10n
  Widget _buildItemCountSummary(int filtered, int total, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.itemsLabel, // <-- LOCALIZED
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

  // No changes needed here, as it receives a localized label
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