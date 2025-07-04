import 'package:flutter/material.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/components/shopping_list_bottom_sheet.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sales_app_mvp/widgets/store_logo.dart';

class ProductDetails extends StatelessWidget {
  final Product product;

  const ProductDetails({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The overall padding for the screen content
      padding: const EdgeInsets.all(20.0),
      // Main layout is a Column
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UPDATED: The new header with Logo and Category boxes
          _buildHeader(),
          const SizedBox(height: 24), // Increased space before the title

          // UPDATED: The product name is now a standalone widget here
          _buildProductName(),
          const SizedBox(height: 12),

          // UPDATED: The image is now in a fixed-size, styled box
          _buildImageContainer(),
          const SizedBox(height: 16),

          // --- The rest of the widgets remain the same ---
          _buildPriceRow(),
          const SizedBox(height: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  // UPDATED: Header now contains the logo and the new category boxes
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // StoreLogo remains on the left
        StoreLogo(
          storeName: product.store,
          height: 48, // Slightly larger for better balance
        ),
        const SizedBox(width: 12),

        // Expanded ensures the category column takes the remaining horizontal space
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NEW: Outlined box for Category
              _buildCategoryBox(product.category),
              const SizedBox(height: 6),
              // NEW: Outlined box for Subcategory
              _buildCategoryBox(product.subcategory),
            ],
          ),
        ),
      ],
    );
  }

  // NEW: A dedicated widget to create the outlined box for categories
  Widget _buildCategoryBox(String text) {
    if (text.isEmpty) {
      return const SizedBox.shrink(); // Don't show a box if there's no text
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        // The outline
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.0),
        // Rounded corners
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // NEW: The product name is now its own widget for better layout control
  Widget _buildProductName() {
    return Text(
      product.name,
      style: const TextStyle(
        fontSize: 22, // Larger font size for a title
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  // REMOVED: The old _buildCategoryRow is no longer needed

  // From ProductDetails.dart

  Widget _buildImageContainer() {
    return Container(
      height: 300, // ** This fixed height creates the uniform layout **
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2), // A subtle background for the box
        borderRadius: BorderRadius.circular(12),
      ),
      // ClipRRect ensures the image respects the container's rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ImageWithAspectRatio(
          imageUrl: product.imageUrl,
          // These are now bound by the container's height
          maxWidth: double.infinity,
          maxHeight: 300,
          // REMOVED: The incorrect `fit: BoxFit.contain` line is gone.
          // Your widget will still use BoxFit.contain because it's hardcoded inside it.
        ),
      ),
    );
  }

  // REMOVED: The old _buildImage() is replaced by _buildImageContainer()

  // --- NO CHANGES BELOW THIS LINE ---

  Widget _buildPriceRow() {
    // Robustly handle the discount percentage string to avoid "%%"
    final cleanPercentage = product.discountPercentage.replaceAll(RegExp(r'[^0-9.]'), '');

    return Row(
      children: [
        Expanded(
          child: _priceBox(
            product.normalPrice.toStringAsFixed(2),
            Colors.grey.shade300,
            const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.lineThrough,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _priceBox(
            '$cleanPercentage%', // Use the cleaned percentage
            Colors.redAccent,
            const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _priceBox(
            product.currentPrice.toStringAsFixed(2),
            Colors.yellow.shade600,
            const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _priceBox(String value, Color bgColor, TextStyle textStyle) {
    return Container(
      height: 75,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(value, style: textStyle, textAlign: TextAlign.center),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.open_in_new,
            label: 'Visit Product',
            onPressed: () => _launchURL(context, product.url),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.add_shopping_cart,
            label: 'Save to list',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // Allows the sheet to be taller
                backgroundColor: AppColors.background, // Match your theme
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => ShoppingListBottomSheet(
                  product: product,
                  onConfirm: (String selectedListName) {},
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textBlack,
        ),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open product link")),
      );
    }
  }
}