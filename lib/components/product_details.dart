import 'package:flutter/material.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart'; // We will use this now
import 'package:sales_app_mvp/components/shopping_list_dialog.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetails extends StatelessWidget {
  final Product product;

  const ProductDetails({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // The widget is no longer a 'Card'. It's a layout for the full screen.
    // The background color is now controlled by the parent Scaffold.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0), // Padding adjusted for app bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Store
          Text(
            product.store,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary, // Text color for dark background
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Row 2: Product Name (already in AppBar, but can keep it for context)
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Row 3 & 4: Category and Subcategory
          _buildCategoryRow('Category', product.category),
          const SizedBox(height: 4),
          _buildCategoryRow('Subcategory', product.subcategory),

          // Row 5: Image (using ImageWithAspectRatio inside an Expanded)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center( // Center the image within the available space
                child: ImageWithAspectRatio(
                  imageUrl: product.imageUrl,
                  // Let the parent Expanded widget provide the size constraints.
                  // BoxFit.contain inside will handle the aspect ratio correctly.
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                ),
              ),
            ),
          ),

          // Row 6: Prices
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _priceBox(
                '€${product.normalPrice.toStringAsFixed(2)}',
                Colors.grey.shade300,
                const TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.black54,
                ),
              ),
              _priceBox(
                '${product.discountPercentage}%',
                Colors.redAccent,
                const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _priceBox(
                '€${product.currentPrice.toStringAsFixed(2)}',
                Colors.yellow.shade600,
                const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 7: Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.open_in_new,
                  label: 'Visit Deal',
                  onPressed: () => _launchURL(context, product.url),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  icon: Icons.add_shopping_cart,
                  label: 'Save',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ShoppingListDialog(product: product, onConfirm: (String selectedListName) {  },),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ... (All helper methods _buildCategoryRow, _priceBox, _buildActionButton, _launchURL remain the same as the last version I provided) ...
  Widget _buildCategoryRow(String label, String value) {
    return Text(
      '$label: $value',
      style: TextStyle(
        fontSize: 14,
        color: Colors.white.withOpacity(0.85),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _priceBox(String value, Color bgColor, TextStyle textStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(value, style: textStyle),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20, color: AppColors.textSecondary),
      label: Text(
        label,
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: AppColors.textSecondary),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.background,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final launched =
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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