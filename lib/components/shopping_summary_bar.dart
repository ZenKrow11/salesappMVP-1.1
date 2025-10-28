import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/shopping_mode_page.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/providers/user_profile_provider.dart';
import 'package:sales_app_mvp/widgets/item_count_widget.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';

class ShoppingSummaryBar extends ConsumerWidget {
  final List<Product> products;
  const ShoppingSummaryBar({super.key, required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userProfileProvider).value;
    final isPremium = user?.isPremium ?? false;

    final int itemLimit = isPremium ? 60 : 30;

    // --- THE FIX IS HERE ---

    // 1. Calculate the TOTAL number of items on the list (for the limit check).
    // An expired item still takes up a slot in the user's list.
    final int totalItemsOnList = products.length;
    final bool overLimit = totalItemsOnList > itemLimit;

    // 2. Calculate the number of ACTIVE, buyable items (for display).
    // This is the number the user actually cares about when looking at the count.
    final List<Product> activeProducts = products.where((item) => item.isOnSale).toList();
    final int activeItemsCount = activeProducts.length;

    // 3. Calculate the total cost based ONLY on the active items.
    final double totalCost = activeProducts.fold(
      0.0,
          (sum, item) => sum + item.currentPrice,
    );

    // 4. Savings can be calculated on all items, as it's useful historical info.
    final double totalSavings = products.fold(
      0.0,
          (sum, item) => sum + (item.normalPrice - item.currentPrice),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.pageBackground,
        border: Border(top: BorderSide(color: theme.background, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              // 5. Display the ACTIVE item count, but use the TOTAL limit.
              _buildItemCountSummary(activeItemsCount, itemLimit, l10n),
              const SizedBox(width: 20),
              _buildSummaryItem(
                l10n.saved,
                '${totalSavings.toStringAsFixed(2)} ${l10n.currencyFrancs}',
                theme.savingsColor,
              ),
              const SizedBox(width: 20),
              _buildSummaryItem(
                l10n.total,
                '${totalCost.toStringAsFixed(2)} ${l10n.currencyFrancs}',
                theme.secondary,
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: () {
              // Use the TOTAL item count for the limit dialog check.
              if (overLimit) {
                _showItemLimitDialog(
                  context,
                  l10n,
                  theme,
                  totalItemsOnList, // Use total here
                  itemLimit,
                );
              } else {
                Navigator.push(
                  context,
                  SlideUpPageRoute(page: const ShoppingModeScreen()),
                );
              }
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

  Future<void> _showItemLimitDialog(
      BuildContext context,
      AppLocalizations l10n,
      AppThemeData theme,
      int currentItems,
      int limit,
      ) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            l10n.itemLimitReachedTitle,
            style: TextStyle(color: theme.secondary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            l10n.itemLimitReachedBody(currentItems, limit),
            style: TextStyle(color: theme.inactive.withOpacity(0.8)),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
                foregroundColor: theme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(l10n.ok, style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemCountSummary(int current, int max, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.itemsLabel.toUpperCase(),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 2),
        ItemCountWidget(filtered: current, total: max, showBackground: false),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              color: valueColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}