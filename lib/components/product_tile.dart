import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_detail_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductScreen extends StatelessWidget {
  final List<Product> products;

  const ProductScreen({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      padding: const EdgeInsets.all(8),
      children: products.map((product) => _buildProductTile(context, product)).toList(),
    );
  }

  Widget _buildProductTile(BuildContext context, Product product) {
    void _showProductDetail() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Consumer(
          builder: (context, ref, _) {
            return ProductDetailOverlay(product: product);
          },
        ),
      );
    }

    return GestureDetector(
      onTap: _showProductDetail,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.all(0), // Margin handled by GridView padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row: Store name and Product name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    product.store,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      product.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            // Second row: Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                height: 100, // Fixed height for the image
                child: (product.imageUrl.isEmpty || !(Uri.tryParse(product.imageUrl)?.hasAbsolutePath ?? false))
                    ? const Center(child: Text("Placeholder Picture", style: TextStyle(color: Colors.grey)))
                    : Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Text("Placeholder Picture", style: TextStyle(color: Colors.grey)));
                        },
                      ),
              ),
            ),
            // Third row: Price details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items with space between
                children: [
                  // Normal price
                  Expanded(
                    child: Text(
                      '${product.normalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  // Discount percentage
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${product.discountPercentage}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  // Current price
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.currentPrice.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}