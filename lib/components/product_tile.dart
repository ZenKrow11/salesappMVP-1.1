// lib/widgets/product_tile.dart

import 'package:flutter/material.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';
import '../models/product.dart';
import '../widgets/store_logo.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        // Using a card provides a nice default shadow and shape
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias, // Ensures content respects the rounded corners
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(
              color: AppColors.primary,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(11), // Slightly less than card's radius
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children to fill width
      children: [
        _buildHeaderRow(),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8), // Clip the image with rounded corners
            child: ImageWithAspectRatio(
              imageUrl: product.imageUrl,
              maxHeight: double.infinity,
              maxWidth: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _buildPriceRow(),
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

  // --- REFACTORED PRICE ROW ---
  Widget _buildPriceRow({double fontSize = 12}) {
    // Define a single, consistent height for all elements in the row.
    const double rowHeight = 36.0;

    return SizedBox(
      height: rowHeight,
      child: Row(
        // Use crossAxisAlignment.stretch to make all children fill the height of the row.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Discount Box
          Expanded(
            // flex: 1 is the default and ensures it takes 1/3 of the space.
            child: _priceBox(
              text: '${product.discountPercentage.replaceAll('%', '')}%',
              bgColor: Colors.red,
              textStyle: TextStyle(
                fontSize: fontSize,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6), // A consistent gap

          // 2. Price Box
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
          const SizedBox(width: 6), // A consistent gap

          // 3. Add to Cart Button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Add to cart functionality
                print("Add ${product.name} to cart");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                // Remove default padding to precisely control the icon's size
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Icon(
                Icons.add_shopping_cart,
                color: AppColors.primary,
                size: fontSize + 8, // Make the icon a bit bigger
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REFACTORED PRICE BOX ---
  // It no longer needs a height parameter as its parent enforces the height.
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
      // Center ensures the text is perfectly aligned both vertically and horizontally.
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