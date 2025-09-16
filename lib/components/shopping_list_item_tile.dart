// lib/components/shopping_list_item_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/product.dart';
import 'package:sales_app_mvp/pages/product_swiper_screen.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/widgets/image_aspect_ratio.dart';
import 'package:sales_app_mvp/widgets/slide_up_page_route.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';

class ShoppingListItemTile extends ConsumerWidget {
  final Product product;
  final List<Product> allProductsInList;

  const ShoppingListItemTile({
    super.key,
    required this.product,
    required this.allProductsInList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final priceString = product.currentPrice.toStringAsFixed(2);

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
      onDoubleTap: () {
        ref.read(shoppingListsProvider.notifier).removeItemFromList(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${product.name}"'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ===================== REFACTOR START =====================
            // The image is now wrapped in a Container to provide the
            // white background and rounded corners, just like the grid tile.
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: ImageWithAspectRatio(
                  imageUrl: product.imageUrl ?? '',
                  fit: BoxFit.cover,
                  maxWidth: 70,
                  maxHeight: 70,
                ),
              ),
            ),
            // ====================== REFACTOR END ======================
            const SizedBox(width: 16),

            // [Title]
            Expanded(
              child: Text(
                product.name,
                style: TextStyle(color: theme.inactive, fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // [Store Logo / Price]
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StoreLogo(
                  storeName: product.store,
                  height: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  '$priceString Fr.',
                  style: TextStyle(
                    color: theme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}