// lib/components/product_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import '../models/product.dart';
import '../widgets/store_logo.dart';

class ProductTile extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return GestureDetector(
      onTap: onTap,
      // ============================================================
      // === PHASE 3 REFACTOR: The "Subtle Card" with Shadow      ===
      // ============================================================
      child: Container(
        decoration: BoxDecoration(
          // 1. The background color of the tile itself
          color: theme.background,
          // 2. The rounded corners for the tile
          borderRadius: BorderRadius.circular(12.0),
          // 3. The custom shadow using the darkest theme color
          boxShadow: [
            BoxShadow(
              color: theme.primary, // Using the darkest color for a deep shadow
              blurRadius: 8.0,      // How soft and spread-out the shadow is
              offset: const Offset(0, 4), // Pushes the shadow down by 4 pixels
            ),
          ],
        ),
        // 4. This ensures that the content (like the image) is clipped to the rounded corners
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildContent(context, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderRow(context, ref),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ImageWithAspectRatio(
              imageUrl: product.imageUrl,
              maxHeight: double.infinity,
              maxWidth: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _buildPriceRow(context, ref),
      ],
    );
  }

  Widget _buildHeaderRow(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        StoreLogo(
          storeName: product.store,
          height: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            product.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.secondary,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context, WidgetRef ref, {double fontSize = 12}) {
    final theme = ref.watch(themeProvider);
    const double rowHeight = 36.0;

    return SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _priceBox(
              text: '${product.discountPercentage}%',
              bgColor: theme.accent,
              textStyle: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _priceBox(
              text: product.currentPrice.toStringAsFixed(2),
              bgColor: Colors.yellow[600],
              textStyle: TextStyle(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ElevatedButton(
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  backgroundColor: theme.background,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => ShoppingListBottomSheet(
                    product: product,
                    onConfirm: (String selectedListName) {},
                  ),
                );
              },
              onPressed: () {
                final activeListName = ref.read(activeShoppingListProvider);
                final notifier = ref.read(shoppingListsProvider.notifier);

                if (activeListName == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No active list. Long press to choose one.'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  notifier.addToList(activeListName, product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to "$activeListName"'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Icon(
                Icons.add_shopping_cart,
                color: theme.primary,
                size: fontSize + 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceBox({
    required String text,
    required Color? bgColor,
    required TextStyle textStyle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: textStyle,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}