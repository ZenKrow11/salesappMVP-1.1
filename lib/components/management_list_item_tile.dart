// lib/components/management_list_item_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';

class ManagementListItemTile extends ConsumerWidget {
  final Product product;
  final List<Product> allProductsInList;
  final VoidCallback onDoubleTap;

  const ManagementListItemTile({
    super.key,
    required this.product,
    required this.allProductsInList,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final priceString = product.currentPrice.toStringAsFixed(2);

    // MODIFICATION: The entire InkWell is now wrapped in a Card.
    return Card(
      elevation: 0, // No shadow needed for this design
      color: theme.background, // Use the card background color from your theme
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Ensures the InkWell ripple stays within the rounded corners
      child: InkWell(
        onTap: () {
          final initialIndex = allProductsInList.indexWhere((p) => p.id == product.id);
          if (initialIndex != -1) {
            Navigator.of(context).push(SlideUpPageRoute(
              page: ProductSwiperScreen(
                products: allProductsInList,
                initialIndex: initialIndex,
              ),
            ));
          }
        },
        onDoubleTap: onDoubleTap,
        child: Padding(
          padding: const EdgeInsets.all(12), // Padding is now inside the InkWell
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: ImageWithAspectRatio(
                  imageUrl: product.imageUrl,
                  maxWidth: 60,
                  maxHeight: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        color: theme.inactive,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    StoreLogo(storeName: product.store, height: 16),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$priceString Fr.',
                style: TextStyle(
                  color: theme.inactive,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}