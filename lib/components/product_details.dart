import 'package:flutter/material.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../widgets/image_aspect_ratio.dart';
import 'shopping_list_dialog.dart';

class ProductDetails extends StatelessWidget {
  final Product product;

  const ProductDetails({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.store,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ImageWithAspectRatio(
              imageUrl: product.imageUrl,
              maxHeight: 250,
              maxWidth: double.infinity,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Chip(
                label: Text(product.category),
                backgroundColor: Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(product.subcategory),
                backgroundColor: Colors.orangeAccent.shade100,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _priceBox(
                product.normalPrice.toStringAsFixed(2),
                Colors.grey.shade300,
                const TextStyle(
                  fontSize: 18,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.black54,
                ),
              ),
              _priceBox(
                '${product.discountPercentage}%',
                Colors.redAccent,
                const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _priceBox(
                product.currentPrice.toStringAsFixed(2),
                Colors.yellow.shade600,
                const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _squareButton(Icons.open_in_new, () async {
                final uri = Uri.parse(product.url);
                try {
                  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                  if (!launched) {
                    throw 'Could not launch URL';
                  }
                } catch (e) {
                  debugPrint('Error launching URL: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Could not open link")),
                  );
                }
              }),
              _squareButton(Icons.view_list, () {
                showDialog(
                  context: context,
                  builder: (_) => ShoppingListDialog(
                    product: product,
                    onConfirm: (listName) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to "$listName"'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceBox(String value, Color bgColor, TextStyle textStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(value, style: textStyle),
    );
  }

  Widget _squareButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 100,
      height: 70,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Icon(icon, size: 32, color: Colors.white),
      ),
    );
  }
}