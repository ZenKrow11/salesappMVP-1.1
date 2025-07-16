import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';
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
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(
              color: AppColors.primary,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
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
        _buildHeaderRow(),
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

  Widget _buildHeaderRow() {
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
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
    const double rowHeight = 36.0;

    return SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _priceBox(
              text: '${product.discountPercentage}%',
              bgColor: Colors.red,
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
              // --- (3) UPDATED: The onLongPress handler now uses the correct bottom sheet ---
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  backgroundColor: AppColors.background,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  // This opens the sheet in "add product to list" mode.
                  builder: (ctx) => ShoppingListBottomSheet(
                    product: product,
                    onConfirm: (String selectedListName) {
                      // The sheet already shows a snackbar on success.
                      // No extra action needed here, but the callback is required by the constructor.
                    },
                  ),
                );
              },
              // The quicksave logic for a regular tap remains unchanged.
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
                backgroundColor: AppColors.secondary,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Icon(
                Icons.add_shopping_cart,
                color: AppColors.primary,
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