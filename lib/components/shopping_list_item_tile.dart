// lib/components/shopping_list_item_tile.dart

import 'package:flutter/material.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';


class ShoppingListItemTile extends StatelessWidget {
  final Product product;
  final List<Product> allProductsInList;
  final AppThemeData theme;
  final VoidCallback onRemove;

  const ShoppingListItemTile({
    super.key,
    required this.product,
    required this.allProductsInList,
    required this.theme,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final priceString = product.currentPrice.toStringAsFixed(2);
    final discount = product.discountPercentage ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: ImageWithAspectRatio(
                imageUrl: product.imageUrl ?? '',
                maxWidth: 70,
                maxHeight: 70,
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
                    style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.store,
                    style: TextStyle(color: theme.inactive.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$priceString Fr.',
                  style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                if (discount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$discount%',
                      style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.close, color: theme.accent, size: 24),
              onPressed: onRemove,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.only(left: 12, right: 4),
            ),
          ],
        ),
      ),
    );
  }
}